defmodule Moov.Disputes do
  @moduledoc """
  Manage card disputes - Visa RDR (Rapid Dispute Resolution) pre-disputes
  and chargebacks from any card network. Moov communicates with the
  networks directly and surfaces the details and deadlines here.

  See https://docs.moov.io/api/money-movement/disputes/.
  """

  alias Moov.Client

  @doc "Lists disputes for an account."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/disputes", opts)
  end

  @doc "Retrieves a single dispute."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, dispute_id) do
    Client.get(client, "/accounts/#{account_id}/disputes/#{dispute_id}")
  end

  @doc "Accepts a dispute (concedes it without submitting evidence)."
  @spec accept(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def accept(%Client{} = client, account_id, dispute_id) do
    Client.post(client, "/accounts/#{account_id}/disputes/#{dispute_id}/accept", %{})
  end

  @doc """
  Uploads a file as dispute evidence (e.g. a receipt, shipping
  confirmation, or signed delivery form).

      Moov.Disputes.upload_evidence_file(client, account_id, dispute_id,
        File.read!("receipt.pdf"),
        filename: "receipt.pdf",
        content_type: "application/pdf"
      )
  """
  @spec upload_evidence_file(Client.t(), String.t(), String.t(), binary(), keyword()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def upload_evidence_file(%Client{} = client, account_id, dispute_id, file_binary, opts)
      when is_binary(file_binary) do
    filename = Keyword.fetch!(opts, :filename)
    content_type = Keyword.fetch!(opts, :content_type)

    Client.request(client, :post, "/accounts/#{account_id}/disputes/#{dispute_id}/evidence-file",
      form_multipart: [file: {file_binary, filename: filename, content_type: content_type}]
    )
  end

  @doc "Submits free-text evidence for a dispute, e.g. a written explanation (`params: %{text: \"...\"}`)."
  @spec upload_evidence_text(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def upload_evidence_text(%Client{} = client, account_id, dispute_id, params)
      when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/disputes/#{dispute_id}/evidence-text", params)
  end

  @doc "Updates a previously uploaded piece of dispute evidence."
  @spec update_evidence(Client.t(), String.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def update_evidence(%Client{} = client, account_id, dispute_id, evidence_id, params)
      when is_map(params) do
    Client.patch(
      client,
      "/accounts/#{account_id}/disputes/#{dispute_id}/evidence/#{evidence_id}",
      params
    )
  end

  @doc "Deletes a piece of dispute evidence (before it's submitted)."
  @spec delete_evidence(Client.t(), String.t(), String.t(), String.t()) ::
          {:ok, term()} | {:error, Moov.Error.t()}
  def delete_evidence(%Client{} = client, account_id, dispute_id, evidence_id) do
    Client.delete(
      client,
      "/accounts/#{account_id}/disputes/#{dispute_id}/evidence/#{evidence_id}"
    )
  end

  @doc "Finalizes and submits all uploaded evidence for a dispute to the card network."
  @spec submit_evidence(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def submit_evidence(%Client{} = client, account_id, dispute_id) do
    Client.post(client, "/accounts/#{account_id}/disputes/#{dispute_id}/evidence/submit", %{})
  end

  @doc "Lists evidence submitted (or pending submission) for a dispute."
  @spec list_evidence(Client.t(), String.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, Moov.Error.t()}
  def list_evidence(%Client{} = client, account_id, dispute_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/disputes/#{dispute_id}/evidence", opts)
  end

  @doc "Retrieves metadata about a single piece of dispute evidence."
  @spec get_evidence(Client.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def get_evidence(%Client{} = client, account_id, dispute_id, evidence_id) do
    Client.get(client, "/accounts/#{account_id}/disputes/#{dispute_id}/evidence/#{evidence_id}")
  end

  @doc "Downloads the raw data (file bytes, or text) for a single piece of dispute evidence."
  @spec get_evidence_data(Client.t(), String.t(), String.t(), String.t()) ::
          {:ok, term()} | {:error, Moov.Error.t()}
  def get_evidence_data(%Client{} = client, account_id, dispute_id, evidence_id) do
    Client.get(
      client,
      "/accounts/#{account_id}/disputes/#{dispute_id}/evidence/#{evidence_id}/data"
    )
  end
end
