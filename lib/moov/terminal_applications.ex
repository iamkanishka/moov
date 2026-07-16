defmodule Moov.TerminalApplications do
  @moduledoc """
  Register and manage terminal applications, required for Tap to Pay on
  iPhone/Android.

  See https://docs.moov.io/api/sources/terminal-applications/.
  """

  alias Moov.Client

  @doc ~S"""
  Creates a terminal application.

  `params` includes `:platform` (`"ios"`/`"android"`) and bundle/package identifiers.
  """
  @spec create(Client.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, params) when is_map(params) do
    Client.post(client, "/terminal-applications", params)
  end

  @doc "Links a terminal application to a merchant account so it can accept Tap to Pay."
  @spec link(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def link(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/terminal-applications", params)
  end

  @doc "Registers a new version of a terminal application."
  @spec create_version(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create_version(%Client{} = client, terminal_application_id, params) when is_map(params) do
    Client.post(client, "/terminal-applications/#{terminal_application_id}/versions", params)
  end

  @doc "Retrieves a terminal application."
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, terminal_application_id) do
    Client.get(client, "/terminal-applications/#{terminal_application_id}")
  end

  @doc "Lists terminal applications."
  @spec list(Client.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, opts \\ []) do
    Client.get(client, "/terminal-applications", opts)
  end

  @doc "Retrieves a terminal application as linked to a specific merchant account."
  @spec get_linked(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get_linked(%Client{} = client, account_id, terminal_application_id) do
    Client.get(client, "/accounts/#{account_id}/terminal-applications/#{terminal_application_id}")
  end

  @doc "Lists terminal applications linked to a merchant account."
  @spec list_linked(Client.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_linked(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/terminal-applications", opts)
  end

  @doc "Gets the configuration a linked terminal application should use."
  @spec get_configuration(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get_configuration(%Client{} = client, account_id, terminal_application_id) do
    Client.get(
      client,
      "/accounts/#{account_id}/terminal-applications/#{terminal_application_id}/configuration"
    )
  end

  @doc "Deletes a terminal application."
  @spec delete(Client.t(), String.t()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def delete(%Client{} = client, terminal_application_id) do
    Client.delete(client, "/terminal-applications/#{terminal_application_id}")
  end
end
