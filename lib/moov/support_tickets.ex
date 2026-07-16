defmodule Moov.SupportTickets do
  @moduledoc """
  Create and track support tickets for your connected accounts - Moov
  responds directly to the merchant, and you can see the thread.

  See https://docs.moov.io/api/tools/support/.
  """

  alias Moov.Client

  @doc "Creates a support ticket for a connected account. `params`: `:subject`, `:message`, `:category`."
  @spec create(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/tickets", params)
  end

  @doc "Lists support tickets for a connected account."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/tickets", opts)
  end

  @doc "Retrieves a single support ticket."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, ticket_id) do
    Client.get(client, "/accounts/#{account_id}/tickets/#{ticket_id}")
  end

  @doc "Lists the messages in a support ticket's thread."
  @spec list_messages(Client.t(), String.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_messages(%Client{} = client, account_id, ticket_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/tickets/#{ticket_id}/messages", opts)
  end

  @doc "Updates a support ticket, e.g. to add a reply or change its status."
  @spec update(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def update(%Client{} = client, account_id, ticket_id, params) when is_map(params) do
    Client.patch(client, "/accounts/#{account_id}/tickets/#{ticket_id}", params)
  end
end
