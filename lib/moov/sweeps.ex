defmodule Moov.Sweeps do
  @moduledoc """
  Automate settlement of a wallet's balance to a linked bank account (or
  pull funds in to cover fees/chargebacks).

  Push payment-method timing: `"ach-credit-same-day"` (cutoff 6pm ET),
  `"ach-credit-standard"` (next-day, 10am ET), `"instant-bank-credit"`
  (instant, via RTP - the recommended choice; `"rtp-credit"` is the same
  rail under a legacy name).

  See https://docs.moov.io/api/money-movement/sweeps/.
  """

  alias Moov.Client

  @doc """
  Creates a sweep configuration for an account.

  `params`: `:wallet_id`, `:push_payment_method_id`, `:pull_payment_method_id`,
  `:status` (`"enabled"`/`"disabled"`), `:starting_balance` (minimum
  balance to keep in the wallet before sweeping the rest out), `:minimum_balance`.
  """
  @spec create_config(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create_config(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/sweep-configs", params)
  end

  @doc "Retrieves a single sweep (an executed instance of a sweep config)."
  @spec get(Client.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, wallet_id, sweep_id) do
    Client.get(client, "/accounts/#{account_id}/wallets/#{wallet_id}/sweeps/#{sweep_id}")
  end

  @doc "Retrieves a sweep configuration."
  @spec get_config(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get_config(%Client{} = client, account_id, sweep_config_id) do
    Client.get(client, "/accounts/#{account_id}/sweep-configs/#{sweep_config_id}")
  end

  @doc "Lists sweeps executed for a wallet."
  @spec list(Client.t(), String.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, wallet_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/wallets/#{wallet_id}/sweeps", opts)
  end

  @doc "Lists sweep configurations for an account."
  @spec list_configs(Client.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_configs(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/sweep-configs", opts)
  end

  @doc "Updates a sweep configuration, e.g. to disable it."
  @spec update_config(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def update_config(%Client{} = client, account_id, sweep_config_id, params)
      when is_map(params) do
    Client.patch(client, "/accounts/#{account_id}/sweep-configs/#{sweep_config_id}", params)
  end
end
