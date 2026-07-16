defmodule Moov.Transfers do
  @moduledoc """
  Move money between two payment methods. This is the core primitive
  everything else in money movement (sweeps, refunds, schedules, payment
  links, invoices) is built on top of.

  See https://docs.moov.io/api/money-movement/transfers/.
  """

  alias Moov.Client

  @doc """
  Creates a transfer.

  `params`:

    * `:source` / `:destination` - each `%{payment_method_id: id}`. A
      `:transfer_id` may be given as the source instead, linking this
      transfer into the same **transfer group** as an earlier one (e.g. for
      multi-party split payments). The source may alternatively be a
      `:payment_token` collected via Moov.js
    * `:amount` - `%{currency: "USD", value: 1204}` (an integer in minor
      units - cents for USD)
    * `:description`, `:metadata`, `:foreign_id` - optional bookkeeping
      fields
    * `:amount_details` - e.g. `%{tip: 100}`
    * `:sales_tax_amount`, `:line_items` - itemized purchase detail; if
      given, `line_items` amounts plus `sales_tax_amount` must sum to
      `:amount`
    * `:facilitator_fee` - `%{total: 50}` or `%{markup: 25}`
    * `:ach_details` - `%{sec_code: "WEB", debit_hold_period: "..."}`
    * `:card_details` - `%{dynamic_descriptor: "...", transaction_source: "..."}`

  ## Options

    * `:idempotent` - defaults to `true` for this function specifically,
      since Moov **requires** an `X-Idempotency-Key` on transfer creation.
      Pass your own `:idempotency_key` (e.g. derived from your own
      order/job ID) to make retries safe across process restarts, not just
      within a single call
    * `:wait_for` - pass `"rail-response"` to receive a fully populated,
      synchronous response (rail-specific status, auth codes, etc) instead
      of just `%{"transferID" => ..., "createdOn" => ...}`. Moov enforces a
      15-second timeout for this; on timeout you still get a `202` with the
      transfer ID, so always handle the "thin" response shape too

  ## Examples

      Moov.Transfers.create(client, account_id, %{
        source: %{payment_method_id: payer_payment_method_id},
        destination: %{payment_method_id: payee_payment_method_id},
        amount: %{currency: "USD", value: 1500},
        description: "Order #1234"
      })

      # ask for the full synchronous response
      Moov.Transfers.create(client, account_id, params, wait_for: "rail-response")
  """
  @spec create(Client.t(), String.t(), map(), keyword()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, account_id, params, opts \\ []) when is_map(params) do
    opts = Keyword.put_new(opts, :idempotent, true)

    Client.request(
      client,
      :post,
      "/accounts/#{account_id}/transfers",
      Keyword.put(opts, :json, params)
    )
  end

  @doc """
  Creates a transfer configuration for an account (default behavior for
  transfers it facilitates, e.g. default facilitator fees).
  """
  @spec create_transfer_config(Client.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def create_transfer_config(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/transfer-config", params)
  end

  @doc """
  Retrieves the available transfer options (eligible rails, estimated
  fees/timing) for a prospective source/destination/amount, without
  actually creating a transfer. Same `params` shape as `create/4`.
  """
  @spec get_transfer_options(Client.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get_transfer_options(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/transfer-options", params)
  end

  @doc "Cancels a transfer that hasn't settled yet (e.g. a queued ACH debit)."
  @spec cancel(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def cancel(%Client{} = client, account_id, transfer_id) do
    Client.post(client, "/accounts/#{account_id}/transfers/#{transfer_id}/cancellations", %{})
  end

  @doc "Lists transfers. Filter with `opts[:query]`, e.g. `query: [status: \"failed\"]`."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/transfers", opts)
  end

  @doc "Retrieves a single transfer."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, transfer_id) do
    Client.get(client, "/accounts/#{account_id}/transfers/#{transfer_id}")
  end

  @doc "Gets the details of a transfer cancellation."
  @spec get_cancellation(Client.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get_cancellation(%Client{} = client, account_id, transfer_id, cancellation_id) do
    Client.get(
      client,
      "/accounts/#{account_id}/transfers/#{transfer_id}/cancellations/#{cancellation_id}"
    )
  end

  @doc "Gets an account's transfer configuration."
  @spec get_transfer_config(Client.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get_transfer_config(%Client{} = client, account_id) do
    Client.get(client, "/accounts/#{account_id}/transfer-config")
  end

  @doc "Updates an account's transfer configuration."
  @spec update_transfer_config(Client.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def update_transfer_config(%Client{} = client, account_id, params) when is_map(params) do
    Client.put(client, "/accounts/#{account_id}/transfer-config", params)
  end

  @doc "Updates a transfer's `:metadata` or `:description` (not its amount or parties, which are immutable)."
  @spec update(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def update(%Client{} = client, account_id, transfer_id, params) when is_map(params) do
    Client.patch(client, "/accounts/#{account_id}/transfers/#{transfer_id}", params)
  end
end
