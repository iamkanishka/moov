defmodule Moov.PaymentMethods do
  @moduledoc """
  A read-only, unified view of every payment method an account has -
  derived automatically from its linked bank accounts, cards, wallets,
  Apple Pay/Google Pay tokens, etc.

  Common `type` values you'll see in responses: `"moov-wallet"`,
  `"ach-debit-fund"`, `"ach-debit-collect"`, `"ach-credit-standard"`,
  `"ach-credit-same-day"`, `"rtp-credit"`, `"instant-bank-credit"`,
  `"card-payment"`, `"push-to-card"`, `"pull-from-card"`,
  `"card-present-payment"`, `"apple-pay"`, `"push-to-apple-pay"`,
  `"pull-from-apple-pay"`, `"google-pay"`.

  See https://docs.moov.io/api/sources/payment-methods/.
  """

  alias Moov.Client

  @doc """
  Lists an account's payment methods. Filter with `opts[:query]`, e.g.
  `query: [source_id: bank_account_id]` to find the payment method(s)
  derived from a specific bank account or card.
  """
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/payment-methods", opts)
  end

  @doc "Retrieves a single payment method."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, payment_method_id) do
    Client.get(client, "/accounts/#{account_id}/payment-methods/#{payment_method_id}")
  end
end
