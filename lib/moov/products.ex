defmodule Moov.Products do
  @moduledoc """
  An account's product catalog - title, base price, description, image,
  and price-modifying options. Maps onto line items in transfers and
  payment links.

  See https://docs.moov.io/api/tools/products/.
  """

  alias Moov.Client

  @doc """
  Creates a product.

  `params`: `:name`, `:description`, `:price` (`%{currency: "USD", value: 2500}`),
  `:image_id` (from `Moov.Images`), `:options` (price-modifying variants).
  """
  @spec create(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def create(%Client{} = client, account_id, params) when is_map(params) do
    Client.post(client, "/accounts/#{account_id}/products", params)
  end

  @doc "Lists an account's active products."
  @spec list(Client.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, Moov.Error.t()}
  def list(%Client{} = client, account_id, opts \\ []) do
    Client.get(client, "/accounts/#{account_id}/products", opts)
  end

  @doc "Retrieves a single product."
  @spec get(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Moov.Error.t()}
  def get(%Client{} = client, account_id, product_id) do
    Client.get(client, "/accounts/#{account_id}/products/#{product_id}")
  end

  @doc "Updates a product and its options."
  @spec update(Client.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, Moov.Error.t()}
  def update(%Client{} = client, account_id, product_id, params) when is_map(params) do
    Client.put(client, "/accounts/#{account_id}/products/#{product_id}", params)
  end

  @doc "Disables a product."
  @spec disable(Client.t(), String.t(), String.t()) :: {:ok, term()} | {:error, Moov.Error.t()}
  def disable(%Client{} = client, account_id, product_id) do
    Client.delete(client, "/accounts/#{account_id}/products/#{product_id}")
  end
end
