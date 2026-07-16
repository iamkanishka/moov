defmodule Moov.PaymentLinks do
  @moduledoc """
  No-code, shareable links (and QR codes) for accepting or sending money
  via card, bank account, or wallet - shareable over email, SMS, or social.

  See https://docs.moov.io/api/money-movement/payment-links/.
  """

  alias Moov.Client

  @doc """
  Creates a payment link.

  `params`: `:amount`, `:description`, `:payment_methods` (which rails to
  accept), or for payout-style links, `:destination` details.
  """
  @spec create(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/payment-links", params)
  end

  @doc "Retrieves a payment link by its code."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, payment_link_code) do
    Client.get(client, "/accounts/#{account_id}/payment-links/#{payment_link_code}")
  end

  @doc "Lists payment links for an account."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/payment-links", opts)
  end

  @doc "Gets a QR code image encoding a payment link's URL."
  @spec get_qr_code(Client.t(), String.t(), String.t()) ::
          {:ok, term()} | {:error, Moov.Error.t()}
  def get_qr_code(%Client{} = client, account_id, payment_link_code) do
    Client.get(client, "/accounts/#{account_id}/payment-links/#{payment_link_code}/qrcode")
  end

  @doc "Updates a payment link."
  @spec update(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def update(%Client{} = client, account_id, payment_link_code, params) when is_map(params) do
    Client.patch(client, "/accounts/#{account_id}/payment-links/#{payment_link_code}", params)
  end

  @doc "Disables a payment link."
  @spec disable(Client.t(), String.t(), String.t()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def disable(%Client{} = client, account_id, payment_link_code) do
    Client.delete(client, "/accounts/#{account_id}/payment-links/#{payment_link_code}")
  end
end
