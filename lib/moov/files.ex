defmodule Moov.Files do
  @moduledoc """
  Upload and list supporting documents for KYC/underwriting (e.g. a photo
  ID, a bank statement, a W-9).

  Limits: 20 MB max per file, 50 files max per account, and only CSV, JPG,
  PDF, or PNG content types are accepted.

  See https://docs.moov.io/api/moov-accounts/files/.
  """

  alias Moov.Client

  @doc """
  Uploads a file for an account.

      Moov.Files.upload(client, account_id, File.read!("license.png"),
        filename: "license.png",
        content_type: "image/png"
      )

  ## Options

    * `:filename` - required
    * `:content_type` - required, one of `"text/csv"`, `"image/jpeg"`,
      `"application/pdf"`, `"image/png"`
  """
  @spec upload(Client.t(), String.t(), binary(), keyword()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def upload(%Client{} = client, account_id, file_binary, opts) when is_binary(file_binary) do
    filename = Keyword.fetch!(opts, :filename)
    content_type = Keyword.fetch!(opts, :content_type)

    Client.request(client, :post, "/accounts/#{account_id}/files",
      form_multipart: [file: {file_binary, filename: filename, content_type: content_type}]
    )
  end

  @doc "Lists files uploaded for an account."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/files", opts)
  end

  @doc "Retrieves metadata about a single uploaded file."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, file_id) do
    Client.get(client, "/accounts/#{account_id}/files/#{file_id}")
  end
end
