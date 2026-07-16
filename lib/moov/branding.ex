defmodule Moov.Branding do
  @moduledoc """
  Light/dark-mode brand colors used across Moov-hosted UIs - onboarding
  forms, payment links, hosted receipts, etc.

  See https://docs.moov.io/api/enrichment/branding/.
  """

  alias Moov.Client

  @doc """
  Creates a brand for an account.

  `params`: `%{light: %{...colors}, dark: %{...colors}, logo_image_id: ...}`.
  """
  @spec create(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/branding", params)
  end

  @doc "Retrieves an account's brand."
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id) do
    Client.get(client, "/accounts/#{account_id}/branding")
  end

  @doc "Partially updates an account's brand."
  @spec update(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def update(%Client{} = client, account_id, params) when is_map(params) do
    Client.patch(client, "/accounts/#{account_id}/branding", params)
  end

  @doc "Creates or fully replaces an account's brand."
  @spec create_or_replace(Client.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def create_or_replace(%Client{} = client, account_id, params) when is_map(params) do
    Client.put(client, "/accounts/#{account_id}/branding", params)
  end
end
