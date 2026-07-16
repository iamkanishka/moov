defmodule Moov.Images do
  @moduledoc """
  Upload and manage an account's image library (used for product catalog
  and line-item visuals). Up to 16 MB, PNG/JPG/WebP, no duplicates.

  See https://docs.moov.io/api/tools/images/.
  """

  alias Moov.Client

  @doc """
  Uploads an image.

      Moov.Images.upload(client, account_id, File.read!("logo.png"),
        filename: "logo.png",
        content_type: "image/png"
      )
  """
  @spec upload(Client.t(), String.t(), binary(), keyword()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def upload(%Client{} = client, account_id, file_binary, opts) when is_binary(file_binary) do
    filename = Keyword.fetch!(opts, :filename)
    content_type = Keyword.fetch!(opts, :content_type)

    Client.request(client, :post, "/accounts/#{account_id}/images",
      form_multipart: [file: {file_binary, filename: filename, content_type: content_type}]
    )
  end

  @doc "Lists image metadata for an account."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/images", opts)
  end

  @doc "Gets metadata for a single image."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, image_id) do
    Client.get(client, "/accounts/#{account_id}/images/#{image_id}")
  end

  @doc "Replaces the binary content of an existing image."
  @spec replace(Client.t(), String.t(), String.t(), binary(), keyword()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def replace(%Client{} = client, account_id, image_id, file_binary, opts)
      when is_binary(file_binary) do
    filename = Keyword.fetch!(opts, :filename)
    content_type = Keyword.fetch!(opts, :content_type)

    Client.request(client, :put, "/accounts/#{account_id}/images/#{image_id}",
      form_multipart: [file: {file_binary, filename: filename, content_type: content_type}]
    )
  end

  @doc "Updates an image's metadata (e.g. its display name)."
  @spec update_metadata(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def update_metadata(%Client{} = client, account_id, image_id, params) when is_map(params) do
    Client.put(client, "/accounts/#{account_id}/images/#{image_id}/metadata", params)
  end

  @doc "Deletes an image."
  @spec delete(Client.t(), String.t(), String.t()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def delete(%Client{} = client, account_id, image_id) do
    Client.delete(client, "/accounts/#{account_id}/images/#{image_id}")
  end
end
