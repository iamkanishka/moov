defmodule Moov.ApplePay do
  @moduledoc """
  Support for Apple Pay as a payment source: accepting it (`apple-pay`),
  disbursing to it (`push-to-apple-pay`), and - for approved use cases -
  pulling from it (`pull-from-apple-pay`). Linking a single token returns
  every supported Apple Pay payment method at once.

  See https://docs.moov.io/api/sources/apple-pay/.
  """

  alias Moov.Client

  @doc "Registers domains for Apple Pay on the Web (`params: %{domain_names: [...]}`)."
  @spec register_domains(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def register_domains(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/apple-pay/domains", params)
  end

  @doc "Updates the registered Apple Pay domains for an account."
  @spec update_domains(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def update_domains(%Client{} = client, account_id, params) when is_map(params) do
    Client.patch(client, "/accounts/#{account_id}/apple-pay/domains", params)
  end

  @doc "Gets the registered Apple Pay domains for an account."
  @spec get_domains(Client.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get_domains(%Client{} = client, account_id) do
    Client.get(client, "/accounts/#{account_id}/apple-pay/domains")
  end

  @doc "Creates an Apple Pay merchant validation session for the client to complete the Apple Pay JS flow."
  @spec create_session(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create_session(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/apple-pay/sessions", params)
  end

  @doc "Exchanges an Apple Pay payment token for a Moov payment method (`params: %{token: ...}`)."
  @spec create_token(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create_token(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/apple-pay/tokens", params)
  end
end
