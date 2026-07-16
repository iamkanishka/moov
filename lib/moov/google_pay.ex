defmodule Moov.GooglePay do
  @moduledoc """
  Support for Google Pay as a payment source.

  See https://docs.moov.io/api/sources/google-pay/.
  """

  alias Moov.Client

  @doc "Exchanges a Google Pay payment token for a Moov payment method (`params: %{token: ...}`)."
  @spec create_token(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create_token(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/google-pay/tokens", params)
  end
end
