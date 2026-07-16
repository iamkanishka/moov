defmodule Moov.Error do
  @moduledoc """
  The error struct returned in the `{:error, error}` tuple from every
  `Moov.*` function, and the exception raised by `!`-suffixed variants.

  Every field Moov could plausibly need to act on programmatically is
  surfaced directly on the struct instead of being buried in an opaque
  response map:

    * `:type` - a normalized, pattern-matchable atom (see `t:type/0`)
    * `:status` - the raw HTTP status code, if the error came from an HTTP
      response (`nil` for transport-level errors)
    * `:message` - a human-readable summary, suitable for logs
    * `:body` - the decoded JSON error body Moov returned, if any. For `422`
      responses this often contains field-level validation details
    * `:request_id` - the value of the `x-request-id` response header, handy
      when contacting Moov support about a specific failed call
    * `:retry_after_ms` - how long to wait before retrying, in milliseconds.
      Populated from a standard `Retry-After` header when present, or as a
      best-effort heuristic scanning the human-readable error message for a
      `"... XXX ms ..."` / `"... XXX milliseconds ..."` hint, since Moov's
      `429`/`422` responses describe the wait time in prose rather than a
      dedicated field (see https://docs.moov.io/api/errors/)
    * `:reason` - the raw underlying reason for transport-level errors
      (e.g. `:timeout`, `:econnrefused`)

  ## Pattern matching on error type

      case Moov.Accounts.get(client, account_id) do
        {:ok, account} ->
          account

        {:error, %Moov.Error{type: :not_found}} ->
          nil

        {:error, %Moov.Error{type: :too_many_requests, retry_after_ms: ms}} ->
          Process.sleep(ms || 1_000)
          Moov.Accounts.get(client, account_id)

        {:error, error} ->
          Logger.error("Moov error: " <> Exception.message(error))
          raise error
      end
  """

  @type type ::
          :bad_request
          | :unauthorized
          | :forbidden
          | :not_found
          | :conflict
          | :unprocessable_entity
          | :too_many_requests
          | :server_error
          | :gateway_timeout
          | :network_error
          | :decode_error
          | :unknown

  @type t :: %__MODULE__{
          type: type(),
          status: pos_integer() | nil,
          message: String.t(),
          body: map() | String.t() | nil,
          request_id: String.t() | nil,
          retry_after_ms: non_neg_integer() | nil,
          reason: term()
        }

  defexception type: :unknown,
               status: nil,
               message: "an unknown error occurred",
               body: nil,
               request_id: nil,
               retry_after_ms: nil,
               reason: nil

  @status_to_type %{
    400 => :bad_request,
    401 => :unauthorized,
    403 => :forbidden,
    404 => :not_found,
    409 => :conflict,
    422 => :unprocessable_entity,
    429 => :too_many_requests,
    500 => :server_error,
    502 => :server_error,
    503 => :server_error,
    504 => :gateway_timeout
  }

  @doc false
  @impl Exception
  def message(%__MODULE__{} = error) do
    base = "Moov API error (#{error.type}): #{error.message}"

    case error.request_id do
      nil -> base
      request_id -> base <> " [x-request-id: #{request_id}]"
    end
  end

  @doc """
  Builds a `Moov.Error` from a raw HTTP response (status, headers, decoded
  body). Used internally by `Moov.Client` - you generally won't call this
  yourself, but it's public and pure so it's easy to unit test.
  """
  @spec from_response(pos_integer(), [{String.t(), String.t()}] | map(), term()) :: t()
  def from_response(status, headers, body) do
    type = Map.get(@status_to_type, status, :unknown)

    %__MODULE__{
      type: type,
      status: status,
      message: error_message(type, body),
      body: body,
      request_id: header_value(headers, "x-request-id"),
      retry_after_ms: retry_after_ms(body, headers)
    }
  end

  @doc """
  Builds a `Moov.Error` from a transport-level failure (DNS, TCP, TLS,
  timeout) where no HTTP response was ever received.
  """
  @spec from_transport_error(term()) :: t()
  def from_transport_error(reason) do
    %__MODULE__{
      type: :network_error,
      message: "request failed before receiving a response: #{inspect(reason)}",
      reason: reason
    }
  end

  @doc """
  Builds a `Moov.Error` for a response body that could not be decoded as
  JSON.
  """
  @spec from_decode_error(term(), String.t()) :: t()
  def from_decode_error(reason, raw_body) do
    %__MODULE__{
      type: :decode_error,
      message: "could not decode response body as JSON: #{inspect(reason)}",
      body: raw_body,
      reason: reason
    }
  end

  defp error_message(_type, %{"error" => message}) when is_binary(message), do: message

  defp error_message(_type, body) when is_map(body) do
    case Enum.find(body, fn {_field, value} -> is_binary(value) and value != "" end) do
      {field, message} -> "#{field}: #{message}"
      nil -> "request failed with a validation or processing error"
    end
  end

  defp error_message(:not_found, _), do: "the requested resource was not found"
  defp error_message(:unauthorized, _), do: "missing or expired authentication"
  defp error_message(:forbidden, _), do: "not authorized to perform this request"
  defp error_message(:too_many_requests, _), do: "rate limited - slow down and retry"
  defp error_message(:server_error, _), do: "Moov experienced an internal error"
  defp error_message(:gateway_timeout, _), do: "a downstream service failed to respond in time"
  defp error_message(_type, _body), do: "request failed"

  # Moov's 429/422 error *messages* describe the wait time in prose (e.g.
  # "retry in 1500 ms") rather than a dedicated JSON field, per
  # https://docs.moov.io/api/errors/. We prefer a standard `Retry-After`
  # header when present and otherwise make a best-effort attempt to scan the
  # message for a "<number> ms|milliseconds" hint. If neither is present,
  # `retry_after_ms` is simply `nil` and `Moov.Retry` falls back to
  # exponential backoff.
  defp retry_after_ms(body, headers) do
    case header_value(headers, "retry-after") do
      nil -> retry_after_ms_from_message(body)
      value -> value |> Integer.parse() |> retry_after_from_seconds()
    end
  end

  @retry_after_pattern ~r/(\d+)\s*(?:ms|milliseconds)\b/i

  defp retry_after_ms_from_message(%{"error" => message}) when is_binary(message) do
    case Regex.run(@retry_after_pattern, message) do
      [_match, digits] -> String.to_integer(digits)
      nil -> nil
    end
  end

  defp retry_after_ms_from_message(_body), do: nil

  defp retry_after_from_seconds({seconds, _rest}), do: seconds * 1_000
  defp retry_after_from_seconds(:error), do: nil

  # Req returns response headers as `%{"lowercase-name" => ["value", ...]}`,
  # but we also accept a plain `%{"name" => "value"}` map or a list of
  # `{name, value}` tuples (e.g. `Plug.Conn.resp_headers/1`) so this stays
  # decoupled from any specific HTTP client.
  defp header_value(headers, name) when is_map(headers) do
    case Map.get(headers, name) do
      [value | _] -> value
      value when is_binary(value) -> value
      _ -> nil
    end
  end

  defp header_value(headers, name) when is_list(headers) do
    Enum.find_value(headers, fn {key, value} ->
      if String.downcase(to_string(key)) == name, do: to_string(value)
    end)
  end
end
