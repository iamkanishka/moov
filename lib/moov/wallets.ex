defmodule Moov.Wallets do
  @moduledoc """
  Moov's internal stored-balance ledger. Every account with the `"wallet"`
  capability gets a `"default"` wallet automatically; create additional
  `"general"` wallets to segment funds (e.g. one wallet per sub-program).

  See https://docs.moov.io/api/sources/wallets/.
  """

  alias Moov.Client

  @doc "Creates an additional wallet for an account (`params: %{wallet_type: \"general\", description: ...}`)."
  @spec create(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/wallets", params)
  end

  @doc "Retrieves a wallet, including its current `available_balance`."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, wallet_id) do
    Client.get(client, "/accounts/#{account_id}/wallets/#{wallet_id}")
  end

  @doc "Lists an account's wallets."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/wallets", opts)
  end

  @doc "Updates a wallet's description/metadata."
  @spec update(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def update(%Client{} = client, account_id, wallet_id, params) when is_map(params) do
    Client.patch(client, "/accounts/#{account_id}/wallets/#{wallet_id}", params)
  end

  @doc "Retrieves a single wallet transaction."
  @spec get_transaction(Client.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get_transaction(%Client{} = client, account_id, wallet_id, transaction_id) do
    Client.get(
      client,
      "/accounts/#{account_id}/wallets/#{wallet_id}/transactions/#{transaction_id}"
    )
  end

  @doc "Lists a wallet's transactions. Filter with `opts[:query]`, e.g. `query: [status: \"completed\"]`."
  @spec list_transactions(Client.t(), String.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_transactions(%Client{} = client, account_id, wallet_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/wallets/#{wallet_id}/transactions", opts)
  end

  @doc "Retrieves a single balance adjustment for an account."
  @spec get_adjustment(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get_adjustment(%Client{} = client, account_id, adjustment_id) do
    Client.get(client, "/accounts/#{account_id}/adjustments/#{adjustment_id}")
  end

  @doc "Lists balance adjustments for an account."
  @spec list_adjustments(Client.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_adjustments(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/adjustments", opts)
  end
end
