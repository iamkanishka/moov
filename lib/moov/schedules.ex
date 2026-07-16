defmodule Moov.Schedules do
  @moduledoc """
  Recurring or future-dated transfers.

  See https://docs.moov.io/api/money-movement/schedules/.
  """

  alias Moov.Client

  @doc """
  Creates a schedule.

  `params`: `:recurrence` (e.g. `%{interval: "monthly", start_date: "2026-07-01"}`),
  and the same `:source`/`:destination`/`:amount` shape as
  `Moov.Transfers.create/4`.
  """
  @spec create(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/schedules", params)
  end

  @doc "Replaces a schedule's configuration."
  @spec update(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def update(%Client{} = client, account_id, schedule_id, params) when is_map(params) do
    Client.put(client, "/accounts/#{account_id}/schedules/#{schedule_id}", params)
  end

  @doc "Retrieves a schedule."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, schedule_id) do
    Client.get(client, "/accounts/#{account_id}/schedules/#{schedule_id}")
  end

  @doc "Lists schedules for an account."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/schedules", opts)
  end

  @doc "Gets a single occurrence of a schedule (e.g. `\"next\"` or a specific date), per `occurrence_filter`."
  @spec get_occurrence(Client.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get_occurrence(%Client{} = client, account_id, schedule_id, occurrence_filter) do
    Client.get(
      client,
      "/accounts/#{account_id}/schedules/#{schedule_id}/occurrences/#{occurrence_filter}"
    )
  end

  @doc "Cancels a schedule."
  @spec cancel(Client.t(), String.t(), String.t()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def cancel(%Client{} = client, account_id, schedule_id) do
    Client.delete(client, "/accounts/#{account_id}/schedules/#{schedule_id}")
  end
end
