defmodule Moov.BankAccounts do
  @moduledoc """
  Link and verify bank accounts. Verification can happen via instant
  micro-deposits, or via Plaid Link / MX (`verify/initiate_verification`).
  Linking a bank account automatically creates payment methods for every
  rail it's eligible for (ACH debit/credit, RTP/instant, wire, etc).

  See https://docs.moov.io/api/sources/bank-accounts/.
  """

  alias Moov.Client

  @doc """
  Links a bank account to an account.

  `params`: `:holder_name`, `:holder_type` (`"individual"` or
  `"business"`), `:routing_number`, `:account_number`, `:bank_account_type`
  (`"checking"` or `"savings"`), or `:plaid_token` / `:mx_authorization_code`
  if linking through an aggregator instead of raw account numbers.
  """
  @spec link(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def link(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/bank-accounts", params)
  end

  @doc "Retrieves a single linked bank account."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, bank_account_id) do
    Client.get(client, "/accounts/#{account_id}/bank-accounts/#{bank_account_id}")
  end

  @doc "Lists an account's linked bank accounts."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/bank-accounts", opts)
  end

  @doc "Unlinks a bank account."
  @spec delete(Client.t(), String.t(), String.t()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def delete(%Client{} = client, account_id, bank_account_id) do
    Client.delete(client, "/accounts/#{account_id}/bank-accounts/#{bank_account_id}")
  end

  @doc "Initiates verification (e.g. via Plaid/MX) for a linked bank account."
  @spec initiate_verification(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def initiate_verification(%Client{} = client, account_id, bank_account_id, params \\ %{}) do
    Client.post(client, "/accounts/#{account_id}/bank-accounts/#{bank_account_id}/verify", params)
  end

  @doc "Completes verification with the data/code returned by the verification provider."
  @spec complete_verification(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def complete_verification(%Client{} = client, account_id, bank_account_id, params)
      when is_map(params) do
    Client.put(client, "/accounts/#{account_id}/bank-accounts/#{bank_account_id}/verify", params)
  end

  @doc "Gets the current verification status for a linked bank account."
  @spec get_verification_status(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get_verification_status(%Client{} = client, account_id, bank_account_id) do
    Client.get(client, "/accounts/#{account_id}/bank-accounts/#{bank_account_id}/verify")
  end

  @doc "Initiates instant micro-deposit verification for a linked bank account."
  @spec initiate_micro_deposits(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def initiate_micro_deposits(%Client{} = client, account_id, bank_account_id) do
    Client.post(
      client,
      "/accounts/#{account_id}/bank-accounts/#{bank_account_id}/micro-deposits",
      %{}
    )
  end

  @doc """
  Completes micro-deposit verification.

  `params`: `%{amounts: [12, 34]}` - the two deposit amounts in cents, in
  any order.
  """
  @spec complete_micro_deposits(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def complete_micro_deposits(%Client{} = client, account_id, bank_account_id, params)
      when is_map(params) do
    Client.put(
      client,
      "/accounts/#{account_id}/bank-accounts/#{bank_account_id}/micro-deposits",
      params
    )
  end
end
