defmodule Moov.AccessTokens do
  @moduledoc """
  Issue short-lived OAuth2 access tokens for client-side integrations
  (Moov.js running in a browser). Call this from your server - never
  expose your public/private key pair to a browser - and hand the
  resulting `access_token` to the client.

  See https://docs.moov.io/api/authentication/access-tokens/.
  """

  alias Moov.Client

  @doc """
  Creates (or refreshes) an access token.

  `params`:

    * `:grant_type` - `"client_credentials"` to mint a new token, or
      `"refresh_token"` to exchange a refresh token for a new one
    * `:scope` - a space-delimited list of scopes, e.g.
      `"/accounts/\#{account_id}/bank-accounts.write /accounts/\#{account_id}/cards.write"`
      (see https://docs.moov.io/api/authentication/scopes/ for the full catalog)
    * `:refresh_token` - required when `:grant_type` is `"refresh_token"`

  This call authenticates with Basic Auth using the same `client` you use
  for every other request (built with `:public_key`/`:private_key`), *not*
  the bearer token it returns.

  ## Examples

      {:ok, %{"access_token" => token, "expires_in" => ttl}} =
        Moov.AccessTokens.create(client, %{
          grant_type: "client_credentials",
          scope: "/accounts/\#{account_id}/wallets.read"
        })
  """
  @spec create(Client.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, params) when is_map(params) do
    Client.post(client, "/oauth2/token", params)
  end

  @doc "Revokes an access token so it can no longer be used. `params: %{token: access_token}`."
  @spec revoke(Client.t(), map()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def revoke(%Client{} = client, params) when is_map(params) do
    Client.post(client, "/oauth2/revoke", params)
  end
end
