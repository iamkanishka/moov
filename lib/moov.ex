defmodule Moov do
  @moduledoc """
  A complete, production-grade Elixir client for the
  [Moov API](https://docs.moov.io/api/).

  This package wraps every resource in Moov's API reference - Moov
  accounts, sources, money movement, account tools, enrichment, and
  authentication - behind small, documented, `@spec`'d modules: `Moov.Accounts`,
  `Moov.Transfers`, `Moov.Wallets`, `Moov.BankAccounts`, `Moov.Cards`,
  `Moov.Disputes`, `Moov.Invoices`, and 25 more. See the module list in the
  sidebar, grouped the same way as https://docs.moov.io/api/.

  ## Installation

      def deps do
        [{:moov, "~> 0.1"}]
      end

  ## Quick start

      client = Moov.Client.new(
        public_key: System.fetch_env!("MOOV_PUBLIC_KEY"),
        private_key: System.fetch_env!("MOOV_PRIVATE_KEY"),
        api_version: "v2026.04.00"
      )

      {:ok, account} =
        Moov.Accounts.create(client, %{
          account_type: "individual",
          profile: %{individual: %{name: %{first_name: "Ada", last_name: "Lovelace"}, email: "ada@example.com"}}
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
          amount: %{currency: "USD", value: 2500}
        })

  Every function returns `{:ok, result}` or `{:error, %Moov.Error{}}` - see
  `Moov.Error` for how to pattern-match on failure types, and `unwrap!/1`
  below if you'd rather raise.

  ## Design philosophy

  Response bodies are returned as plain maps with their original camelCase
  string keys, exactly as Moov sends them (`account["accountID"]`, not a
  rigid struct) - request bodies, on the other hand, accept idiomatic
  snake_case keys and are camelCased automatically (see `Moov.CaseConverter`).
  This keeps the library forward-compatible with new fields Moov adds to
  responses over time, while staying pleasant to write Elixir against.
  Errors, retries, idempotency, and webhook verification are still fully
  typed and structured (`Moov.Error`, `Moov.Webhook.Event`) since those are
  exactly the places where stringly-typed data would bite you.

  ## Raising instead of pattern matching

      Moov.Accounts.get(client, account_id) |> Moov.unwrap!()

  is equivalent to:

      case Moov.Accounts.get(client, account_id) do
        {:ok, account} -> account
        {:error, error} -> raise error
      end
  """

  @doc """
  Unwraps an `{:ok, result}` tuple to `result`, or raises the `Moov.Error`
  inside an `{:error, error}` tuple.

  Works with the return value of *any* function in this library - pipe
  into it instead of writing `case`/`with` everywhere you're comfortable
  letting failures crash the calling process.

  ## Examples

      iex> Moov.unwrap!({:ok, %{"accountID" => "acc_123"}})
      %{"accountID" => "acc_123"}

      iex> Moov.unwrap!({:error, %Moov.Error{type: :not_found, message: "not found"}})
      ** (Moov.Error) Moov API error (not_found): not found
  """
  @spec unwrap!({:ok, term()} | {:error, Moov.Error.t()}) :: term()
  def unwrap!({:ok, result}), do: result
  def unwrap!({:error, %Moov.Error{} = error}), do: raise(error)
end
