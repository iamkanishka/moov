defmodule Moov.Receipts do
  @moduledoc """
  Branded receipts (using an account's `Moov.Branding`) sent when a
  transfer is initiated/confirmed, refunded, or fails.

  See https://docs.moov.io/api/money-movement/receipts/.
  """

  alias Moov.Client

  @doc """
  Creates receipts for one or more transfers.

  `params`: `%{transfer_ids: [...], receipt_types: ["transferInitiated", "transferConfirmation"]}`
  (or similar - see Moov's dashboard for the exact set of receipt types
  your account supports).
  """
  @spec create(Client.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, params) when is_map(params) do
    Client.post(client, "/receipts", params)
  end

  @doc "Lists receipts that have been sent."
  @spec list(Client.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, opts \\ []) do
    Client.get(client, "/receipts", opts)
  end
end
