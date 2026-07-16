# Moov

[![Hex.pm](https://img.shields.io/hexpm/v/moov.svg)](https://hex.pm/packages/moov)
[![Docs](https://img.shields.io/badge/docs-hexdocs-purple)](https://hexdocs.pm/moov)

A complete, production-grade Elixir client for the [Moov API](https://docs.moov.io/api/) -
accounts, sources, money movement, account tools, enrichment, and
authentication. Built on [`Req`](https://hex.pm/packages/req), with
automatic retries, idempotency, telemetry, and webhook signature
verification built in.

This isn't a partial wrapper around a couple of endpoints - every resource
in Moov's API reference has a corresponding module:

| Moov accounts          | Sources                     | Money movement      | Account tools         | Enrichment          | Auth                |
| ---------------------- | --------------------------- | ------------------- | --------------------- | ------------------- | ------------------- |
| `Moov.Accounts`        | `Moov.BankAccounts`         | `Moov.Transfers`    | `Moov.Images`         | `Moov.Branding`     | `Moov.AccessTokens` |
| `Moov.Billing`         | `Moov.Cards`                | `Moov.Sweeps`       | `Moov.Products`       | `Moov.Enrichment`   | `Moov.E2EE`         |
| `Moov.Capabilities`    | `Moov.ApplePay`             | `Moov.Refunds`      | `Moov.SupportTickets` | `Moov.Institutions` |                     |
| `Moov.Files`           | `Moov.GooglePay`            | `Moov.Disputes`     |                       |                     |                     |
| `Moov.OnboardingLinks` | `Moov.PaymentMethods`       | `Moov.CardIssuing`  |                       |                     |                     |
| `Moov.ResolutionLinks` | `Moov.TerminalApplications` | `Moov.Invoices`     |                       |                     |                     |
| `Moov.PartnerBilling`  | `Moov.Wallets`              | `Moov.PaymentLinks` |                       |                     |                     |
| `Moov.Representatives` |                             | `Moov.Receipts`     |                       |                     |                     |
| `Moov.Underwriting`    |                             | `Moov.Schedules`    |                       |                     |                     |

Plus `Moov.Client` (the engine), `Moov.Error`, `Moov.Retry`,
`Moov.Webhook`, `Moov.Telemetry`, and `Moov.CaseConverter` underneath all
of it.

## Installation

```elixir
def deps do
  [{:moov, "~> 0.1"}]
end
```

## Quick start

```elixir
client = Moov.Client.new(
  public_key: System.fetch_env!("MOOV_PUBLIC_KEY"),
  private_key: System.fetch_env!("MOOV_PRIVATE_KEY"),
  api_version: "v2026.04.00"
)

{:ok, account} =
  Moov.Accounts.create(client, %{
    account_type: "individual",
    profile: %{
      individual: %{
        name: %{first_name: "Ada", last_name: "Lovelace"},
        email: "ada@example.com"
      }
    }
  })

{:ok, bank_account} =
  Moov.BankAccounts.link(client, account["accountID"], %{
    holder_name: "Ada Lovelace",
    holder_type: "individual",
    routing_number: "021000021",
    account_number: "123456789",
    bank_account_type: "checking"
  })

{:ok, transfer} =
  Moov.Transfers.create(client, account["accountID"], %{
    source: %{payment_method_id: source_payment_method_id},
    destination: %{payment_method_id: bank_account["paymentMethodID"]},
    amount: %{currency: "USD", value: 2_500}
  })
```

Every function returns `{:ok, result}` or `{:error, %Moov.Error{}}`. Prefer
exceptions instead? Pipe into `Moov.unwrap!/1`:

```elixir
account = Moov.Accounts.get(client, account_id) |> Moov.unwrap!()
```

## Configuration

Build a client explicitly, or set defaults once via application
environment and call `Moov.Client.new()` everywhere:

```elixir
# config/runtime.exs
config :moov,
  public_key: System.get_env("MOOV_PUBLIC_KEY"),
  private_key: System.get_env("MOOV_PRIVATE_KEY"),
  api_version: "v2026.04.00"
```

```elixir
client = Moov.Client.new()
```

**Always set `:api_version` explicitly.** Moov's API silently falls back to
legacy `v2024.01.00` behavior if no `X-Moov-Version` header is sent at all -
this library never omits it, but it's worth knowing the underlying API
works that way.

Client-side / Moov.js integrations authenticate with a bearer token instead
of your secret key pair:

```elixir
{:ok, %{"access_token" => token}} =
  Moov.AccessTokens.create(server_client, %{
    grant_type: "client_credentials",
    scope: "/accounts/#{account_id}/wallets.read"
  })

browser_client = Moov.Client.new(access_token: token)
```

## Design philosophy

- **Responses are plain maps with their original camelCase string keys**
  (`account["accountID"]`, not a rigid struct). This keeps the library
  forward-compatible with new fields Moov adds over time and avoids
  pretending to fully model an evolving JSON API in static Elixir types.
- **Requests accept idiomatic snake_case keys** and are camelCased
  automatically (`Moov.CaseConverter`), so you write `%{legal_business_name: "Acme"}`
  instead of `%{"legalBusinessName" => "Acme"}`.
- **The boundary is still fully structured.** Errors (`Moov.Error`),
  retries (`Moov.Retry`), idempotency, and webhook events
  (`Moov.Webhook.Event`) are real, documented, `@spec`'d data - exactly the
  places where "just a map" would bite you.
- **No hidden global state.** `Moov.Client.new/1` returns a plain,
  immutable struct. Build one per request, store it in a `GenServer`, hold
  several at once for different partner credentials - whatever your
  application needs. Nothing requires an OTP application tree.

## Idempotency

Moov requires an `X-Idempotency-Key` header on transfer creation to safely
deduplicate retried requests. `Moov.Transfers.create/4` sets this for you
automatically - a key is generated **once** and reused across every retry
attempt for that call, since generating a fresh key per attempt would
defeat the entire point.

Pin your own key (e.g. derived from your own order/job ID) to make retries
safe across process restarts too, not just within a single call:

```elixir
Moov.Transfers.create(client, account_id, params, idempotency_key: "order-#{order.id}")
```

Any write call can opt in the same way: `idempotent: true` or an explicit
`idempotency_key:`.

## Retries

Transient failures - `429`, `5xx`, and network errors - are retried
automatically with exponential backoff and full jitter (`Moov.Retry`).
Non-transient failures (`400`, `401`, `404`, `409`, `422`, ...) are never
retried, since retrying a request Moov rejected as invalid will just fail
again.

```elixir
# override per call
Moov.Accounts.get(client, account_id, max_retries: 0)

# or for the client's lifetime
client = Moov.Client.new(max_retries: 5)
```

## Errors

```elixir
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
```

See `Moov.Error` for the full field list (`:type`, `:status`, `:message`,
`:body`, `:request_id`, `:retry_after_ms`, `:reason`).

## Webhooks

```elixir
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
  end
end
```

Make sure no JSON parser has consumed the body before this runs - the
signature is computed over the _raw_ bytes Moov sent.

## Telemetry

```elixir
:telemetry.attach(
  "log-moov-requests",
  [:moov, :request, :stop],
  fn _event, %{duration: duration}, metadata, _config ->
    Logger.info(
      "Moov #{metadata.method} #{metadata.path} -> " <>
        "#{inspect(metadata.status || metadata.error_type)} in " <>
        "#{System.convert_time_unit(duration, :native, :millisecond)}ms"
    )
  end,
  nil
)
```

See `Moov.Telemetry` for the full event list (`[:moov, :request, :start | :stop | :exception]`,
`[:moov, :retry]`).

## File uploads

`Moov.Files`, `Moov.Images`, and `Moov.Disputes.upload_evidence_file/5` all
accept raw binary content plus a filename/content type and handle the
`multipart/form-data` encoding for you:

```elixir
Moov.Files.upload(client, account_id, File.read!("license.png"),
  filename: "license.png",
  content_type: "image/png"
)
```

## Testing code that uses this library

This library is built on `Req`, so your own tests can use
[`Req.Test`](https://hexdocs.pm/req/Req.Test.html) to stub Moov without any
real network I/O:

```elixir
# test/support/moov_stub.ex
Req.Test.stub(MyApp.MoovStub, fn conn ->
  Req.Test.json(conn, %{"accountID" => "acct_test_1"})
end)

client = Moov.Client.new(req_options: [plug: {Req.Test, MyApp.MoovStub}])
```

See `test/support/test_support.ex` and `test/moov/client_test.exs` in this
repository for more complete examples (idempotency, retries, error
mapping, multipart uploads).

## Development

```sh
mix deps.get
mix test
mix quality   # mix format --check-formatted && mix credo --strict && mix dialyzer
mix docs
```

## License

MIT - see [LICENSE](LICENSE).

This is an independent, community-maintained client and is not officially
affiliated with or endorsed by Moov Financial, Inc.
