defmodule Moov.CardIssuing do
  @moduledoc """
  Issue spending cards tied to a Moov wallet, and inspect authorizations
  and settled card transactions against them.

  See https://docs.moov.io/api/money-movement/issuing/.
  """

  alias Moov.Client

  @doc """
  Creates (issues) a spending card.

  `params`: `:wallet_id`, `:card_holder` info, and limits/controls Moov
  supports for issued cards (e.g. spending controls, expiration).
  """
  @spec create_issued_card(Client.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def create_issued_card(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/issuing/#{account_id}/issued-cards", params)
  end

  @doc "Lists spending cards issued for an account."
  @spec list_issued_cards(Client.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_issued_cards(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/issuing/#{account_id}/issued-cards", opts)
  end

  @doc "Retrieves a single issued (spending) card."
  @spec get_issued_card(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get_issued_card(%Client{} = client, account_id, issued_card_id) do
    Client.get(client, "/issuing/#{account_id}/issued-cards/#{issued_card_id}")
  end

  @doc "Updates an issued card's controls/status."
  @spec update_issued_card(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def update_issued_card(%Client{} = client, account_id, issued_card_id, params)
      when is_map(params) do
    Client.patch(client, "/issuing/#{account_id}/issued-cards/#{issued_card_id}", params)
  end

  @doc "Gets PCI-sensitive details (full PAN/CVV) for an issued card. Handle the response with care."
  @spec get_issued_card_details(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get_issued_card_details(%Client{} = client, account_id, issued_card_id) do
    Client.get(client, "/issuing/#{account_id}/issued-cards/#{issued_card_id}/details")
  end

  @doc "Lists authorizations against issued cards for an account."
  @spec list_authorizations(Client.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_authorizations(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/issuing/#{account_id}/authorizations", opts)
  end

  @doc "Retrieves a single authorization."
  @spec get_authorization(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get_authorization(%Client{} = client, account_id, authorization_id) do
    Client.get(client, "/issuing/#{account_id}/authorizations/#{authorization_id}")
  end

  @doc "Lists the lifecycle events (authorized, reversed, expired, ...) for a single authorization."
  @spec list_authorization_events(Client.t(), String.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_authorization_events(%Client{} = client, account_id, authorization_id, opts \\ []) do
    Client.get(client, "/issuing/#{account_id}/authorizations/#{authorization_id}/events", opts)
  end

  @doc "Lists settled card transactions for an account's issued cards."
  @spec list_card_transactions(Client.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_card_transactions(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/issuing/#{account_id}/card-transactions", opts)
  end

  @doc "Retrieves a single settled card transaction."
  @spec get_card_transaction(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get_card_transaction(%Client{} = client, account_id, card_transaction_id) do
    Client.get(client, "/issuing/#{account_id}/card-transactions/#{card_transaction_id}")
  end
end
