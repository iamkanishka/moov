defmodule Moov.OnboardingLinks do
  @moduledoc """
  Hosted, co-branded onboarding forms you can send merchants instead of
  building your own UI.

  See https://docs.moov.io/api/moov-accounts/onboarding/.
  """

  alias Moov.Client

  @doc """
  Creates an onboarding invite. `params` typically includes things like
  `:account_type`, requested `:capabilities`, and where to redirect
  afterward (`:redirect_uri` or similar) - see the Moov dashboard for the
  exact fields your onboarding flow supports.
  """
  @spec create(Client.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, params) when is_map(params) do
    Client.post(client, "/onboarding-invites", params)
  end

  @doc "Lists onboarding invites."
  @spec list(Client.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, opts \\ []) do
    Client.get(client, "/onboarding-invites", opts)
  end

  @doc "Retrieves a single onboarding invite by its code."
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, code) do
    Client.get(client, "/onboarding-invites/#{code}")
  end

  @doc "Revokes an onboarding invite so its link can no longer be used."
  @spec revoke(Client.t(), String.t()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def revoke(%Client{} = client, code) do
    Client.delete(client, "/onboarding-invites/#{code}")
  end
end
