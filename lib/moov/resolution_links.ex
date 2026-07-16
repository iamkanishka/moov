defmodule Moov.ResolutionLinks do
  @moduledoc """
  Temporary, secure links you can send merchants to resolve outstanding
  requirements (additional KYC info, document uploads) after their initial
  onboarding. Added in API version `v2026.04.00`.

  See https://docs.moov.io/api/moov-accounts/resolution-links/.
  """

  alias Moov.Client

  @doc "Creates a resolution link for an account that has outstanding requirements."
  @spec create(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, account_id, params \\ %{}) do
    Client.post(client, "/accounts/#{account_id}/resolution-links", params)
  end

  @doc "Retrieves a single resolution link by its code."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, resolution_link_code) do
    Client.get(client, "/accounts/#{account_id}/resolution-links/#{resolution_link_code}")
  end

  @doc "Lists resolution links created for an account."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/resolution-links", opts)
  end

  @doc "Deletes (invalidates) a resolution link."
  @spec delete(Client.t(), String.t(), String.t()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def delete(%Client{} = client, account_id, resolution_link_code) do
    Client.delete(client, "/accounts/#{account_id}/resolution-links/#{resolution_link_code}")
  end
end
