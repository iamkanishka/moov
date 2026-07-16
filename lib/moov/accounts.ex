defmodule Moov.Accounts do
  @moduledoc """
  Create and manage Moov accounts - the core entity representing your
  platform, or one of your platform's merchants/users.

  See https://docs.moov.io/api/moov-accounts/accounts/.
  """

  alias Moov.Client

  @doc """
  Creates an account.

  `params` (snake_case keys are camelCased automatically, see
  `Moov.CaseConverter`):

    * `:account_type` - `"individual"` or `"business"` (required)
    * `:profile` - `%{individual: %{...}}` or `%{business: %{...}}`
      (required). Individual profiles take `:name` (`:first_name`,
      `:last_name`, optional `:middle_name`/`:suffix`), `:email`, `:phone`,
      `:address`, `:birth_date`, `:government_id`. Business profiles take
      `:legal_business_name`, `:business_type` (`"soleProprietorship"`,
      `"llc"`, `"partnership"`, `"privateCorporation"`,
      `"publicCorporation"`, `"trust"`, ...), `:address`, `:phone`,
      `:email`, `:website`, `:tax_id`, `:industry_codes`, `:industry`
    * `:capabilities` - capabilities to request immediately, e.g.
      `["transfers", "wallet", "send-funds", "collect-funds"]` (optional -
      see `Moov.Capabilities.create/3` to request these later instead)
    * `:terms_of_service` - `%{token: token}` from Moov.js, or
      `%{manual: %{accepted_date: ..., accepted_ip: ..., accepted_user_agent: ..., accepted_domain: ...}}`.
      Required before enabling `wallet`, `send-funds`, `collect-funds`, or
      `card-issuing`
    * `:settings` - e.g.
      `%{ach_payment: %{company_name: "..."}, card_payment: %{statement_descriptor: "..."}}`
    * `:customer_support` - business-only: phone/email/address/website shown
      on card transactions
    * `:foreign_id` - your own identifier for this account
    * `:mode` - `"sandbox"` or `"production"` (facilitator/top-level
      accounts only - sub-accounts inherit the facilitator's mode)

  Requires scope `/accounts.write`.

  ## Examples

      Moov.Accounts.create(client, %{
        account_type: "business",
        profile: %{
          business: %{
            legal_business_name: "Whole Body Fitness LLC",
            business_type: "llc",
            email: "ops@wholebodyfitness.example"
          }
        }
      })
  """
  @spec create(Client.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, params) when is_map(params) do
    Client.post(client, "/accounts", params)
  end

  @doc """
  Lists accounts accessible to your platform.

  Supported `opts[:query]` filters include `:name`, `:email`, `:type`,
  `:foreign_id`, `:include_disabled`, `:count`, `:skip`.
  """
  @spec list(Client.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, opts \\ []) do
    Client.get(client, "/accounts", opts)
  end

  @doc "Retrieves a single account by ID."
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id) do
    Client.get(client, "/accounts/#{account_id}")
  end

  @doc """
  Updates an account. `params` accepts the same shape as `create/2`'s
  `:profile`/`:settings`/`:customer_support` (partial updates are merged).
  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def update(%Client{} = client, account_id, params) when is_map(params) do
    Client.patch(client, "/accounts/#{account_id}", params)
  end

  @doc "Deletes an account."
  @spec delete(Client.t(), String.t()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def delete(%Client{} = client, account_id) do
    Client.delete(client, "/accounts/#{account_id}")
  end

  @doc """
  Shares a connection with another account, e.g. so a partner platform can
  see one of your merchant accounts. `params` takes `:account_id` (the
  account to connect with) among other fields documented by Moov.
  """
  @spec create_connection(Client.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def create_connection(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/connections", params)
  end

  @doc "Lists accounts connected to the given account."
  @spec list_connected_accounts(Client.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_connected_accounts(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/connected-accounts", opts)
  end

  @doc """
  Generates a terms-of-service token, used in `create/2`'s
  `:terms_of_service` when collecting acceptance via Moov.js rather than
  recording it manually.
  """
  @spec create_tos_token(Client.t(), keyword()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create_tos_token(%Client{} = client, opts \\ []) do
    Client.get(client, "/tos-token", opts)
  end
end
