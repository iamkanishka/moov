defmodule Moov.UUID do
  @moduledoc """
  A tiny, dependency-free UUID v4 generator.

  Moov requires an `X-Idempotency-Key` header on transfer-creation calls (and
  accepts one on several other write endpoints) to safely deduplicate retried
  requests. Rather than pull in an external UUID library for this one need,
  `Moov.Client` generates RFC 4122 version 4 UUIDs using only `:crypto` from
  Erlang/OTP, which is always available.
  """

  @doc """
  Generates a random version 4 (random) UUID as a lowercase, hyphenated
  string, e.g. `"d6903402-776f-48d6-8fba-0358959d34e5"`.

  ## Examples

      iex> uuid = Moov.UUID.generate()
      iex> String.match?(uuid, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
      true
  """
  @spec generate() :: String.t()
  def generate do
    <<u0::48, _::4, u1::12, _::2, u2::62>> = :crypto.strong_rand_bytes(16)

    # Set the version (4) and variant (RFC 4122) bits per spec.
    <<a::32, b::16, c::16, d::16, e::48>> = <<u0::48, 4::4, u1::12, 2::2, u2::62>>

    [a, b, c, d, e]
    |> Enum.map(&Integer.to_string(&1, 16))
    |> Enum.zip([8, 4, 4, 4, 12])
    |> Enum.map(fn {hex, width} -> String.pad_leading(String.downcase(hex), width, "0") end)
    |> Enum.join("-")
  end
end
