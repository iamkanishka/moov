defmodule Moov.Underwriting do
  @moduledoc """
  Submit underwriting details for a business account - e.g. average
  transaction size, expected annual revenue/card volume, and whether the
  business is a money services business.

  See https://docs.moov.io/api/moov-accounts/underwriting/.
  """

  alias Moov.Client

  @doc """
  Creates or updates underwriting details for an account. This is the
  preferred entry point - `update/3` (`PUT`) is being sunset in favor of
  calling this repeatedly as details change.

  `params` typically includes `:average_transaction_amount`,
  `:max_transaction_amount`, `:volume_by_customer_type`,
  `:average_monthly_transaction_volume`, `:volume_by_payment_type`,
  `:cards_volume_5_percent_or_more` and similar fields - see the Moov
  dashboard's underwriting requirements for the exact set for your account
  type.
  """
  @spec create_or_update(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create_or_update(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/underwriting", params)
  end

  @doc "Retrieves underwriting details for an account."
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id) do
    Client.get(client, "/accounts/#{account_id}/underwriting")
  end

  @doc """
  Updates underwriting details via `PUT`.

  > #### Deprecated {: .warning}
  >
  > Moov is sunsetting this endpoint - prefer `create_or_update/3`.
  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def update(%Client{} = client, account_id, params) when is_map(params) do
    Client.put(client, "/accounts/#{account_id}/underwriting", params)
  end
end
