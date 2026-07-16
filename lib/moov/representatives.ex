defmodule Moov.Representatives do
  @moduledoc """
  Manage the controllers and owners of a business account, required for
  KYB on LLCs, partnerships, and private corporations.

  At least one representative must be a **controller** (has significant
  management responsibility); every individual with a **25%+ ownership**
  stake must be added as an **owner**. A single representative can be both.

  See https://docs.moov.io/api/moov-accounts/representatives/.
  """

  alias Moov.Client

  @doc """
  Adds a representative to a business account.

  `params`: `:name` (`:first_name`, `:last_name`, ...), `:email`, `:phone`,
  `:address`, `:birth_date`, `:government_id`, `:responsibilities` -
  `%{is_controller: true, is_owner: true, ownership_percentage: 40, job_title: "CEO"}`.
  """
  @spec create(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/representatives", params)
  end

  @doc "Retrieves a single representative."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, representative_id) do
    Client.get(client, "/accounts/#{account_id}/representatives/#{representative_id}")
  end

  @doc "Lists representatives for a business account."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/representatives", opts)
  end

  @doc "Updates a representative."
  @spec update(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def update(%Client{} = client, account_id, representative_id, params) when is_map(params) do
    Client.patch(client, "/accounts/#{account_id}/representatives/#{representative_id}", params)
  end

  @doc "Removes a representative from a business account."
  @spec delete(Client.t(), String.t(), String.t()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def delete(%Client{} = client, account_id, representative_id) do
    Client.delete(client, "/accounts/#{account_id}/representatives/#{representative_id}")
  end
end
