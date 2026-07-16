defmodule Moov.UUIDTest do
  use ExUnit.Case, async: true

  @uuid_v4_regex ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

  test "generates a well-formed version 4 UUID" do
    assert Moov.UUID.generate() =~ @uuid_v4_regex
  end

  test "generates unique values across many calls" do
    uuids = for _ <- 1..1_000, do: Moov.UUID.generate()
    assert length(Enum.uniq(uuids)) == 1_000
  end

  test "every generated UUID matches the v4/RFC 4122 variant bit pattern" do
    for _ <- 1..200 do
      assert Moov.UUID.generate() =~ @uuid_v4_regex
    end
  end
end
