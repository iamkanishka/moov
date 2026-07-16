defmodule Moov.Cards do
  @moduledoc """
  Link and manage cards as payment sources.

  See https://docs.moov.io/api/sources/cards/.
  """

  alias Moov.Client

  @doc """
  Links a card to an account.

  `params`: `:card_number`, `:card_cvv`, `:expiration` (`%{month: "01", year: "28"}`),
  `:holder_name`, `:billing_address`, or `:card_on_file` token from
  Moov.js if you collected card data client-side (recommended, to keep raw
  PANs out of your servers / PCI scope).
  """
  @spec link(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def link(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/cards", params)
  end

  @doc "Lists an account's linked cards."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/cards", opts)
  end

  @doc "Retrieves a single linked card."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, card_id) do
    Client.get(client, "/accounts/#{account_id}/cards/#{card_id}")
  end

  @doc "Updates a card, e.g. its billing address after the card account updater reports a change."
  @spec update(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def update(%Client{} = client, account_id, card_id, params) when is_map(params) do
    Client.patch(client, "/accounts/#{account_id}/cards/#{card_id}", params)
  end

  @doc "Disables a linked card."
  @spec disable(Client.t(), String.t(), String.t()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def disable(%Client{} = client, account_id, card_id) do
    Client.delete(client, "/accounts/#{account_id}/cards/#{card_id}")
  end
end
