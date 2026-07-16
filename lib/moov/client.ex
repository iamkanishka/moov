defmodule Moov.Client do
  @moduledoc """
  Builds and sends requests to the Moov API.

  Every `Moov.*` resource module (`Moov.Accounts`, `Moov.Transfers`, ...) is a
  thin, documented wrapper around this module - you can always drop down to
  `request/4` directly for an endpoint that doesn't have a dedicated wrapper
  yet, or to pass low-level options none of the wrappers expose.

  ## Creating a client

      # explicit credentials
      client = Moov.Client.new(public_key: "...", private_key: "...")

      # or pull defaults from `config :moov, ...` (see `Moov.Config`)
      client = Moov.Client.new()

      # client-side / Moov.js flows authenticate with a bearer token instead
      client = Moov.Client.new(access_token: token)

  A `Moov.Client` is a plain, immutable struct - hold on to it, store it in
  a `GenServer`'s state, build a fresh one per request, whatever suits your
  application. Nothing about this library requires a singleton or an OTP
  application tree.

  ## Sending requests

      Moov.Client.get(client, "/accounts/\#{account_id}")
      Moov.Client.post(client, "/accounts", %{account_type: "individual", ...})
      Moov.Client.patch(client, "/accounts/\#{account_id}", %{profile: ...})
      Moov.Client.delete(client, "/accounts/\#{account_id}")

  All of these (and `request/4` itself) return `{:ok, body}` on any `2xx`
  response or `{:error, %Moov.Error{}}` otherwise. `body` is the decoded JSON
  response with its original camelCase string keys, exactly as Moov sent it.
  Raise instead of pattern matching with `Moov.unwrap!/1`.

  ## Request options

  Every sending function accepts:

    * `:query` - a map or keyword list of query string parameters
    * `:headers` - a list of `{name, value}` tuples to merge in (these win
      over any header this module sets, except where noted)
    * `:idempotent` - when `true` and no `:idempotency_key` is given, a
      random UUID v4 is generated once and reused across all retry attempts
      for this call. `Moov.Transfers.create/3` sets this for you
    * `:idempotency_key` - an explicit `X-Idempotency-Key` value, e.g. one
      derived from your own job/event ID so retries across process restarts
      stay deduplicated too
    * `:wait_for` - set to `"rail-response"` to add the `X-Wait-For` header
      Moov's transfer/refund endpoints use to opt into a slower, fully
      populated synchronous response
    * `:form_multipart` - for multipart file uploads (`Moov.Files`, `Moov.Images`,
      dispute evidence), e.g.
      `form_multipart: [file: {binary, filename: "id.png", content_type: "image/png"}]`.
      Mutually exclusive with `:json` for a given call
    * `:api_version`, `:max_retries`, `:receive_timeout` - per-call
      overrides of the client's defaults
  """

  alias Moov.{CaseConverter, Error, Retry, Telemetry, UUID}

  @type auth :: {:basic, String.t(), String.t()} | {:bearer, String.t()} | nil
  @type method :: :get | :post | :patch | :put | :delete

  @type t :: %__MODULE__{
          base_url: String.t(),
          api_version: String.t(),
          auth: auth(),
          max_retries: non_neg_integer(),
          receive_timeout: timeout(),
          req_options: keyword()
        }

  defstruct base_url: "https://api.moov.io",
            api_version: "v2026.04.00",
            auth: nil,
            max_retries: 3,
            receive_timeout: 30_000,
            req_options: []

  @doc """
  Builds a new client.

  Accepts everything `Moov.Config` resolves from application environment,
  plus:

    * `:base_url` - defaults to `"https://api.moov.io"`
    * `:api_version` - the `X-Moov-Version` to send on every request.
      **Always set this explicitly in production** - Moov silently falls
      back to legacy `v2024.01.00` behavior if it's omitted entirely, which
      this library never does, but it's worth knowing the API does
    * `:public_key` / `:private_key` - Basic Auth credentials (server-side
      integrations)
    * `:access_token` - a bearer token (client-side / Moov.js integrations,
      typically obtained via `Moov.AccessTokens.create/2`); takes precedence
      over `:public_key`/`:private_key` if both are given
    * `:max_retries` - default number of retries for transient failures
      (default: `3`)
    * `:receive_timeout` - default response timeout in milliseconds
      (default: `30_000`)
    * `:req_options` - a keyword list merged into every `Req.request/1`
      call, e.g. `req_options: [plug: {Req.Test, MyApp.MoovStub}]` in tests,
      or `req_options: [connect_options: [proxy: ...]]` behind a corporate
      proxy
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    opts = Moov.Config.resolve(opts)

    %__MODULE__{
      base_url: Keyword.fetch!(opts, :base_url),
      api_version: Keyword.fetch!(opts, :api_version),
      auth: build_auth(opts),
      max_retries: Keyword.fetch!(opts, :max_retries),
      receive_timeout: Keyword.fetch!(opts, :receive_timeout),
      req_options: Keyword.fetch!(opts, :req_options)
    }
  end

  defp build_auth(opts) do
    case Keyword.get(opts, :access_token) do
      token when is_binary(token) and token != "" ->
        {:bearer, token}

      _ ->
        case {Keyword.get(opts, :public_key), Keyword.get(opts, :private_key)} do
          {pub, priv} when is_binary(pub) and is_binary(priv) and pub != "" and priv != "" ->
            {:basic, pub, priv}

          _ ->
            nil
        end
    end
  end

  @doc "Sends a `GET` request. See the moduledoc for shared options."
  @spec get(t(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def get(%__MODULE__{} = client, path, opts \\ []), do: request(client, :get, path, opts)

  @doc "Sends a `POST` request with `body` as the JSON payload."
  @spec post(t(), String.t(), map(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def post(%__MODULE__{} = client, path, body \\ %{}, opts \\ []) do
    request(client, :post, path, Keyword.put(opts, :json, body))
  end

  @doc "Sends a `PATCH` request with `body` as the JSON payload."
  @spec patch(t(), String.t(), map(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def patch(%__MODULE__{} = client, path, body \\ %{}, opts \\ []) do
    request(client, :patch, path, Keyword.put(opts, :json, body))
  end

  @doc "Sends a `PUT` request with `body` as the JSON payload."
  @spec put(t(), String.t(), map(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def put(%__MODULE__{} = client, path, body \\ %{}, opts \\ []) do
    request(client, :put, path, Keyword.put(opts, :json, body))
  end

  @doc "Sends a `DELETE` request."
  @spec delete(t(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def delete(%__MODULE__{} = client, path, opts \\ []), do: request(client, :delete, path, opts)

  # :telemetry.span/3 returns `term()`, so dialyzer cannot trace the return type of
  # `request/4` through the span call. The function is correct; suppress the cascade.
  @dialyzer {:nowarn_function, request: 4}

  @doc """
  The low-level entry point every other function in this module (and every
  `Moov.*` resource wrapper) ultimately calls. See the moduledoc for the
  full list of supported `opts`.
  """
  @spec request(t(), method(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def request(%__MODULE__{} = client, method, path, opts \\ [])
      when method in [:get, :post, :patch, :put, :delete] do
    # Resolve the idempotency key *once*, outside the retry loop, so every
    # retry attempt for this call reuses the same key. Generating a fresh
    # key per attempt would defeat the entire point of idempotency.
    opts = Keyword.put_new(opts, :idempotency_key, resolve_idempotency_key(opts))
    max_retries = Keyword.get(opts, :max_retries, client.max_retries)
    metadata = %{method: method, path: path}

    Telemetry.span(metadata, fn ->
      result =
        Retry.run(
          fn -> send_request(client, method, path, opts) end,
          max_retries: max_retries,
          on_retry: fn attempt, delay_ms, error ->
            Telemetry.retry(
              Map.merge(metadata, %{attempt: attempt, delay_ms: delay_ms, error: error})
            )
          end
        )

      {result, Map.merge(metadata, stop_metadata(result))}
    end)
    |> unwrap()
  end

  defp resolve_idempotency_key(opts) do
    cond do
      key = Keyword.get(opts, :idempotency_key) -> key
      Keyword.get(opts, :idempotent, false) -> UUID.generate()
      true -> nil
    end
  end

  defp stop_metadata({:ok, %{status: status}}), do: %{status: status, error_type: nil}

  defp stop_metadata({:error, %Error{type: type, status: status}}),
    do: %{status: status, error_type: type}

  defp unwrap({:ok, %{body: body}}), do: {:ok, body}
  defp unwrap({:error, %Error{}} = error), do: error

  defp send_request(client, method, path, opts) do
    req_opts = build_req_options(client, method, path, opts)

    case Req.request(req_opts) do
      {:ok, %Req.Response{status: status, body: body, headers: headers}}
      when status in 200..299 ->
        {:ok, %{status: status, body: body, headers: headers}}

      {:ok, %Req.Response{status: status, body: body, headers: headers}} ->
        {:error, Error.from_response(status, headers, body)}

      {:error, exception} ->
        {:error, Error.from_transport_error(unwrap_transport_error(exception))}
    end
  end

  defp build_req_options(client, method, path, opts) do
    headers =
      [
        {"accept", "application/json"},
        {"x-moov-version", Keyword.get(opts, :api_version, client.api_version)}
      ]
      |> add_header(auth_header(client.auth))
      |> add_header(idempotency_header(Keyword.get(opts, :idempotency_key)))
      |> add_header(wait_for_header(Keyword.get(opts, :wait_for)))
      |> Kernel.++(Keyword.get(opts, :headers, []))

    [
      method: method,
      base_url: client.base_url,
      url: path,
      headers: headers,
      params: build_query(Keyword.get(opts, :query)),
      receive_timeout: Keyword.get(opts, :receive_timeout, client.receive_timeout),
      retry: false
    ]
    |> maybe_put_json(Keyword.get(opts, :json))
    |> maybe_put_form(Keyword.get(opts, :form_multipart))
    |> Keyword.merge(client.req_options)
  end

  defp maybe_put_form(req_opts, nil), do: req_opts
  defp maybe_put_form(req_opts, form), do: Keyword.put(req_opts, :form_multipart, form)

  # Req wraps low-level errors in %Req.TransportError{reason: reason}.
  # Unwrap it so Moov.Error.reason holds the raw atom (e.g. :timeout, :econnrefused)
  # that callers can pattern-match on, not a Req-specific struct.
  defp unwrap_transport_error(%{__struct__: Req.TransportError, reason: reason}), do: reason
  defp unwrap_transport_error(other), do: other

  defp build_query(nil), do: %{}
  defp build_query(query) when is_map(query), do: CaseConverter.to_camel_case(query)

  defp build_query(query) when is_list(query),
    do: query |> Map.new() |> CaseConverter.to_camel_case()

  defp maybe_put_json(req_opts, nil), do: req_opts

  defp maybe_put_json(req_opts, body),
    do: Keyword.put(req_opts, :json, CaseConverter.to_camel_case(body))

  defp add_header(headers, nil), do: headers
  defp add_header(headers, header), do: [header | headers]

  defp auth_header({:basic, public_key, private_key}) do
    {"authorization", "Basic " <> Base.encode64("#{public_key}:#{private_key}")}
  end

  defp auth_header({:bearer, token}), do: {"authorization", "Bearer " <> token}
  defp auth_header(nil), do: nil

  defp idempotency_header(nil), do: nil
  defp idempotency_header(key), do: {"x-idempotency-key", key}

  defp wait_for_header(nil), do: nil
  defp wait_for_header(value), do: {"x-wait-for", value}
end
