defmodule Moov.Capabilities do
  @moduledoc """
  Request and manage the [capabilities](https://docs.moov.io/guides/accounts/capabilities/)
  an account needs - e.g. `"transfers"`, `"wallet"`, `"send-funds"`,
  `"collect-funds"`, `"card-issuing"`.

  See https://docs.moov.io/api/moov-accounts/capabilities/.
  """

  alias Moov.Client

  @doc """
  Requests one or more capabilities for an account.

  `params`: `%{capabilities: ["transfers", "wallet"]}`. Moov evaluates
  underwriting/KYC requirements asynchronously - check `status` on the
  returned capability (or subscribe to `capability.updated` webhooks)
  rather than assuming it's immediately `"enabled"`.
  """
  @spec create(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/capabilities", params)
  end

  @doc "Lists an account's capabilities and their statuses."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/capabilities", opts)
  end

  @doc ~S'Retrieves a single capability, e.g. `"transfers"` or `"wallet"`.'
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, capability_id) do
    Client.get(client, "/accounts/#{account_id}/capabilities/#{capability_id}")
  end

  @doc "Disables a previously enabled capability."
  @spec disable(Client.t(), String.t(), String.t()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def disable(%Client{} = client, account_id, capability_id) do
    Client.delete(client, "/accounts/#{account_id}/capabilities/#{capability_id}")
  end
end
