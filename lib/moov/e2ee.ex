defmodule Moov.E2EE do
  @moduledoc """
  End-to-end encryption support: fetch a public key to encrypt sensitive
  payloads (e.g. raw card/bank account numbers) client-side before they
  ever reach your server.

  See https://docs.moov.io/api/authentication/e2ee/.
  """

  alias Moov.Client

  @doc "Generates a public key for end-to-end encryption."
  @spec create_key(Client.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create_key(%Client{} = client, params \\ %{}) do
    Client.post(client, "/end-to-end-keys", params)
  end

  @doc """
  Verifies a JWE token end-to-end encrypted with a key from `create_key/2`.
  Intended for debugging your client-side encryption integration, not for
  production traffic.
  """
  @spec debug_token(Client.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def debug_token(%Client{} = client, params) when is_map(params) do
    Client.post(client, "/debug/end-to-end-token", params)
  end
end
