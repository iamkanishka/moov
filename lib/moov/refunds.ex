defmodule Moov.Refunds do
  @moduledoc """
  Refund or cancel card transfers.

  Moov offers two mechanisms: the original `refunds` sub-resource, and the
  newer, more flexible `reversals` sub-resource which can both cancel an
  uncaptured/unsettled transfer and refund a settled one. New integrations
  should generally prefer `create_reversal/3`.

  See https://docs.moov.io/api/money-movement/refunds/.
  """

  alias Moov.Client

  @doc """
  Cancels or refunds a card transfer via the `reversals` sub-resource.

  `params`: `%{amount: %{currency: "USD", value: 500}}` for a partial
  refund, or omit `:amount` to refund/cancel the full amount.
  """
  @spec create_reversal(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def create_reversal(%Client{} = client, account_id, transfer_id, params \\ %{}) do
    Client.post(client, "/accounts/#{account_id}/transfers/#{transfer_id}/reversals", params)
  end

  @doc """
  Creates a refund via the original `refunds` sub-resource.

  `params`: `%{amount: %{currency: "USD", value: 500}}` for a partial
  refund, or omit `:amount` to refund the full amount.
  """
  @spec create(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, account_id, transfer_id, params \\ %{}) do
    Client.post(client, "/accounts/#{account_id}/transfers/#{transfer_id}/refunds", params)
  end

  @doc "Lists refunds issued against a transfer."
  @spec list(Client.t(), String.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, transfer_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/transfers/#{transfer_id}/refunds", opts)
  end

  @doc "Retrieves a single refund."
  @spec get(Client.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, transfer_id, refund_id) do
    Client.get(client, "/accounts/#{account_id}/transfers/#{transfer_id}/refunds/#{refund_id}")
  end
end
