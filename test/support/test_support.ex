defmodule Moov.TestSupport do
  @moduledoc """
  Shared helpers for testing against this library without any real network
  I/O, using Req's built-in `Req.Test` plug support.

  ## Usage

      defmodule Moov.SomeResourceTest do
        use ExUnit.Case, async: true
        import Moov.TestSupport

        test "creates a thing" do
          Req.Test.stub(__MODULE__, fn conn ->
            Req.Test.json(conn, %{"id" => "thing_1"})
          end)

          assert {:ok, %{"id" => "thing_1"}} =
                   Moov.SomeResource.create(stub_client(__MODULE__), %{})
        end
      end
  """

  @doc """
  Builds a `Moov.Client` configured with dummy Basic Auth credentials and
  routed through `Req.Test` under the given stub `name` (typically the
  test module itself, `__MODULE__`).
  """
  @spec stub_client(atom(), keyword()) :: Moov.Client.t()
  def stub_client(name, overrides \\ []) do
    Moov.Client.new(
      Keyword.merge(
        [
          public_key: "test_public_key",
          private_key: "test_private_key",
          api_version: "v2026.04.00",
          max_retries: 0,
          req_options: [plug: {Req.Test, name}]
        ],
        overrides
      )
    )
  end
end
