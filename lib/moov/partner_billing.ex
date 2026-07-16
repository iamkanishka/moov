defmodule Moov.PartnerBilling do
  @moduledoc """
  Residuals, fee revenue, and pricing agreements for **partner** accounts
  (platforms/SaaS/marketplaces). `account_id` here must be your partner
  account ID, found under Dashboard -> Settings - not a regular merchant
  account ID.

  See https://docs.moov.io/api/moov-accounts/partner-billing/.
  """

  alias Moov.Client

  @doc "Retrieves a single residual."
  @spec get_residual(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get_residual(%Client{} = client, account_id, residual_id) do
    Client.get(client, "/accounts/#{account_id}/residuals/#{residual_id}")
  end

  @doc "Lists residuals for a partner account."
  @spec list_residuals(Client.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_residuals(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/residuals", opts)
  end

  @doc "Lists the fees that make up a residual."
  @spec list_residual_fees(Client.t(), String.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_residual_fees(%Client{} = client, account_id, residual_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/residuals/#{residual_id}/fees", opts)
  end

  @doc "Lists fee revenue for a partner account."
  @spec list_fee_revenue(Client.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_fee_revenue(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/fee-revenue", opts)
  end

  @doc "Lists partner pricing agreements."
  @spec list_partner_pricing_agreements(Client.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_partner_pricing_agreements(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/partner-pricing-agreements", opts)
  end
end
