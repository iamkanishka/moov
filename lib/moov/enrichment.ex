defmodule Moov.Enrichment do
  @moduledoc """
  "Form shortening" lookups that autofill form fields from publicly
  available data, so your users have fewer fields to type (and fewer
  typos to make).

  See https://docs.moov.io/api/enrichment/form-shortening/.
  """

  alias Moov.Client

  @doc "Address autocomplete. `opts[:query]`: `[search: \"123 Main\"]` (and similar narrowing fields)."
  @spec address(Client.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def address(%Client{} = client, opts \\ []) do
    Client.get(client, "/enrichment/address", opts)
  end

  @doc "Enriches a business profile from an email address. `opts[:query]`: `[email: \"...\"]`."
  @spec profile(Client.t(), keyword()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def profile(%Client{} = client, opts \\ []) do
    Client.get(client, "/enrichment/profile", opts)
  end

  @doc "Retrieves a generated avatar image for a given unique ID (e.g. an account ID)."
  @spec avatar(Client.t(), String.t()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def avatar(%Client{} = client, unique_id) do
    Client.get(client, "/avatars/#{unique_id}")
  end

  @doc "Lists valid industries (the values accepted by `Moov.Accounts.create/2`'s `:industry` field)."
  @spec industries(Client.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def industries(%Client{} = client, opts \\ []) do
    Client.get(client, "/industries", opts)
  end

  @doc "Looks up an ACH-participating financial institution by routing number. `opts[:query]`: `[routing_number: \"...\"]`."
  @spec search_ach_institution(Client.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def search_ach_institution(%Client{} = client, opts \\ []) do
    Client.get(client, "/institutions/ach/search", opts)
  end
end
