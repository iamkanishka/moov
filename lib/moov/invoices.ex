defmodule Moov.Invoices do
  @moduledoc """
  Create and manage invoices. Added in API version `v2026.04.00`.

  Invoice `status` values: `"draft"`, `"unpaid"`, `"payment-pending"`,
  `"paid"`, `"overdue"`, `"canceled"`.

  See https://docs.moov.io/api/money-movement/invoices/.
  """

  alias Moov.Client

  @doc """
  Creates an invoice.

  `params`: `:line_items`, `:due_date`, `:customer_account_id` (or
  recipient contact info for a non-Moov customer), `:memo`, `:metadata`.
  """
  @spec create(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/invoices", params)
  end

  @doc "Lists invoices for an account."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/invoices", opts)
  end

  @doc "Retrieves a single invoice."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, invoice_id) do
    Client.get(client, "/accounts/#{account_id}/invoices/#{invoice_id}")
  end

  @doc "Updates an invoice (e.g. its due date, line items, or status while still a draft)."
  @spec update(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def update(%Client{} = client, account_id, invoice_id, params) when is_map(params) do
    Client.patch(client, "/accounts/#{account_id}/invoices/#{invoice_id}", params)
  end

  @doc "Creates a payment resource against an invoice (records a payment toward it)."
  @spec create_payment(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def create_payment(%Client{} = client, account_id, invoice_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/invoices/#{invoice_id}/payments", params)
  end

  @doc "Lists payments recorded against an invoice."
  @spec list_payments(Client.t(), String.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_payments(%Client{} = client, account_id, invoice_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/invoices/#{invoice_id}/payments", opts)
  end

  @doc "Deletes a draft invoice."
  @spec delete(Client.t(), String.t(), String.t()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def delete(%Client{} = client, account_id, invoice_id) do
    Client.delete(client, "/accounts/#{account_id}/invoices/#{invoice_id}")
  end
end
