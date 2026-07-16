defmodule Moov.Billing do
  @moduledoc """
  Fee plans, fee plan agreements, statements, and per-account fees.

  See https://docs.moov.io/api/moov-accounts/billing/.
  """

  alias Moov.Client

  @doc "Creates a fee plan agreement for an account. `params` includes `:fee_plan_id`."
  @spec create_fee_plan_agreement(Client.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def create_fee_plan_agreement(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/fee-plan-agreements", params)
  end

  @doc "Lists an account's fee plan agreements."
  @spec list_fee_plan_agreements(Client.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_fee_plan_agreements(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/fee-plan-agreements", opts)
  end

  @doc "Lists fee plans available to an account."
  @spec list_fee_plans(Client.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_fee_plans(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/fee-plans", opts)
  end

  @doc "Retrieves a single billing statement."
  @spec get_statement(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get_statement(%Client{} = client, account_id, statement_id) do
    Client.get(client, "/accounts/#{account_id}/statements/#{statement_id}")
  end

  @doc "Lists an account's billing statements."
  @spec list_statements(Client.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_statements(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/statements", opts)
  end

  @doc "Looks up fees for an account given a set of transfer-shaped criteria in `params`."
  @spec fetch_fees(Client.t(), String.t(), map()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def fetch_fees(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/fees/.fetch", params)
  end

  @doc "Retrieves the fees that have been assessed against an account."
  @spec list_fees(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_fees(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/fees", opts)
  end
end
