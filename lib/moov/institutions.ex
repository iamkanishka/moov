defmodule Moov.Institutions do
  @moduledoc """
  Look up financial institutions and validate routing numbers, including
  which rails (ACH, RTP, wire) a given institution supports.

  See https://docs.moov.io/api/enrichment/institutions/.
  """

  alias Moov.Client

  @doc """
  Looks up financial institutions. `opts[:query]` supports filters such as
  `[name: "...", routing_number: "...", rail: "ach"]` - see Moov's docs for
  the full filter set.
  """
  @spec search(Client.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def search(%Client{} = client, opts \\ []) do
    Client.get(client, "/institutions", opts)
  end
end
