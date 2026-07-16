defmodule Moov.Webhook do
  @moduledoc """
  Verifies that an incoming webhook request really came from Moov, and
  parses its payload into a `Moov.Webhook.Event`.

  Moov signs every webhook delivery with an HMAC-SHA512 of
  `timestamp <> "|" <> nonce <> "|" <> webhookID`, keyed with the signing
  secret shown in the Moov Dashboard for that webhook
  (`https://dashboard.moov.io/developers/webhooks`), and sends the result
  hex-encoded in the `X-Signature` header alongside the `X-Timestamp`,
  `X-Nonce`, and `X-Webhook-ID` headers it was computed from. See
  https://docs.moov.io/guides/webhooks/check-webhook-signatures/.

  ## Usage with Plug/Phoenix

      def webhook_controller(conn, _params) do
        {:ok, raw_body, conn} = Plug.Conn.read_body(conn)
        secret = Application.fetch_env!(:my_app, :moov_webhook_secret)

        case Moov.Webhook.construct_event(raw_body, conn.req_headers, secret) do
          {:ok, %Moov.Webhook.Event{type: "transfer.updated", data: data}} ->
            MyApp.Transfers.handle_update(data)
            send_resp(conn, 200, "")

          {:ok, _event} ->
            send_resp(conn, 200, "")

          {:error, :invalid_signature} ->
            send_resp(conn, 400, "invalid signature")

          {:error, reason} ->
            send_resp(conn, 400, "bad request: " <> inspect(reason))
        end
      end

  Note that for the signature to validate you must use the *raw,
  unparsed* request body - if you're using Phoenix, make sure no JSON
  parser has already consumed and re-serialized it (a custom
  `Plug.Parsers` body reader that caches the raw body is the standard
  fix).
  """

  defmodule Event do
    @moduledoc """
    A parsed webhook event.

    `data` is intentionally left as a plain, camelCase-keyed map (or its
    `to_snake_case/0`-converted form, see `Moov.Webhook.Event.to_snake_case/1`)
    since its shape depends entirely on `type`. See
    https://docs.moov.io/guides/webhooks/webhook-events/ for the schema of
    every event type Moov currently sends.
    """

    @type t :: %__MODULE__{
            id: String.t() | nil,
            type: String.t(),
            data: map(),
            created_on: String.t() | nil
          }

    defstruct [:id, :type, :data, :created_on]

    @doc "Returns a copy of the event with `data`'s keys converted to snake_case strings."
    @spec to_snake_case(t()) :: t()
    def to_snake_case(%__MODULE__{data: data} = event) do
      %{event | data: Moov.CaseConverter.to_snake_case(data)}
    end
  end

  @known_event_types ~w(
    account.created account.updated account.deleted
    representative.created representative.updated representative.deleted representative.disabled
    capability.requested capability.updated
    bankAccount.created bankAccount.updated bankAccount.deleted
    transfer.created transfer.updated
    walletTransaction.updated
    dispute.created dispute.updated
    paymentMethod.enabled paymentMethod.disabled
    balance.updated
    cancellation.created cancellation.updated
    refund.created refund.updated
    networkID.updated
    card.autoUpdated
    billingStatement.created
    invoice.created invoice.updated
    sweep.created sweep.updated
  )

  @doc """
  Returns the list of webhook event type identifiers documented by Moov as
  of this package's release. This list is informational only - Moov may add
  new event types at any time and `construct_event/3` will still parse them
  successfully (`type` is always returned as a plain string, never an atom).
  """
  @spec known_event_types() :: [String.t()]
  def known_event_types, do: @known_event_types

  @doc """
  Verifies the HMAC-SHA512 signature of a webhook delivery.

  `headers` may be a list of `{key, value}` tuples (as returned by
  `Plug.Conn.req_headers/1`) or a map; header name lookups are
  case-insensitive either way.

  Returns `:ok` or `{:error, :missing_signature_headers | :invalid_signature}`.
  """
  @spec verify_signature(Enumerable.t(), String.t()) ::
          :ok | {:error, :missing_signature_headers | :invalid_signature}
  def verify_signature(headers, secret) when is_binary(secret) do
    with {:ok, timestamp} <- fetch_header(headers, "x-timestamp"),
         {:ok, nonce} <- fetch_header(headers, "x-nonce"),
         {:ok, webhook_id} <- fetch_header(headers, "x-webhook-id"),
         {:ok, signature} <- fetch_header(headers, "x-signature") do
      if valid_signature?(timestamp, nonce, webhook_id, signature, secret) do
        :ok
      else
        {:error, :invalid_signature}
      end
    else
      :error -> {:error, :missing_signature_headers}
    end
  end

  @doc """
  The pure, lower-level signature check: given the four header values and
  the signing secret, returns `true` if `signature` matches the expected
  HMAC-SHA512, using a constant-time comparison.
  """
  @spec valid_signature?(String.t(), String.t(), String.t(), String.t(), String.t()) :: boolean()
  def valid_signature?(timestamp, nonce, webhook_id, signature, secret) do
    expected = expected_signature(timestamp, nonce, webhook_id, secret)
    secure_compare(expected, String.downcase(signature))
  end

  # `:crypto.hash_equals/2` performs a constant-time comparison, but raises
  # `ArgumentError` if the two binaries differ in length rather than simply
  # returning `false`. A malformed or forged `X-Signature` header (wrong
  # length) must not crash the caller, so we check length first - comparing
  # lengths isn't a meaningful timing side-channel here, since the correct
  # length (128 lowercase hex characters) is public knowledge, not a secret.
  defp secure_compare(a, b) when byte_size(a) == byte_size(b), do: :crypto.hash_equals(a, b)
  defp secure_compare(_a, _b), do: false

  @doc """
  Computes the expected hex-encoded HMAC-SHA512 signature for the given
  header values and signing secret, without comparing it to anything. This
  is the exact value Moov puts in `X-Signature`.
  """
  @spec expected_signature(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def expected_signature(timestamp, nonce, webhook_id, secret) do
    payload = timestamp <> "|" <> nonce <> "|" <> webhook_id

    :crypto.mac(:hmac, :sha512, secret, payload)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Verifies the signature on a raw webhook request body and, if valid,
  JSON-decodes it into a `Moov.Webhook.Event`.

  `raw_body` must be the exact, unmodified bytes Moov sent - decode it
  *after* verifying, never before.
  """
  @spec construct_event(String.t(), Enumerable.t(), String.t()) ::
          {:ok, Event.t()} | {:error, :missing_signature_headers | :invalid_signature | term()}
  def construct_event(raw_body, headers, secret) when is_binary(raw_body) do
    with :ok <- verify_signature(headers, secret),
         {:ok, decoded} <- Jason.decode(raw_body) do
      {:ok,
       %Event{
         id: Map.get(decoded, "eventID"),
         type: Map.get(decoded, "type"),
         data: Map.get(decoded, "data", %{}),
         created_on: Map.get(decoded, "createdOn")
       }}
    end
  end

  defp fetch_header(headers, name) do
    case do_fetch_header(headers, name) do
      nil -> :error
      value -> {:ok, value}
    end
  end

  defp do_fetch_header(headers, name) when is_map(headers) do
    Enum.find_value(headers, fn {key, value} ->
      if String.downcase(to_string(key)) == name, do: to_string(value)
    end)
  end

  defp do_fetch_header(headers, name) do
    Enum.find_value(headers, fn {key, value} ->
      if String.downcase(to_string(key)) == name, do: to_string(value)
    end)
  end
end
