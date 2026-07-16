defmodule Moov.WebhookTest do
  use ExUnit.Case, async: true

  alias Moov.Webhook
  alias Moov.Webhook.Event

  @secret "whsec_test_secret"
  @timestamp "1700000000"
  @nonce "n0nce-123"
  @webhook_id "wh_abc"

  defp valid_headers do
    signature = Webhook.expected_signature(@timestamp, @nonce, @webhook_id, @secret)

    [
      {"x-timestamp", @timestamp},
      {"x-nonce", @nonce},
      {"x-webhook-id", @webhook_id},
      {"x-signature", signature},
      {"content-type", "application/json"}
    ]
  end

  describe "expected_signature/4" do
    test "is deterministic for the same inputs" do
      sig1 = Webhook.expected_signature(@timestamp, @nonce, @webhook_id, @secret)
      sig2 = Webhook.expected_signature(@timestamp, @nonce, @webhook_id, @secret)
      assert sig1 == sig2
    end

    test "is a 128-character lowercase hex string (SHA-512 digest)" do
      sig = Webhook.expected_signature(@timestamp, @nonce, @webhook_id, @secret)
      assert String.match?(sig, ~r/^[0-9a-f]{128}$/)
    end

    test "changes if any input changes" do
      base = Webhook.expected_signature(@timestamp, @nonce, @webhook_id, @secret)
      assert Webhook.expected_signature("9999999999", @nonce, @webhook_id, @secret) != base

      assert Webhook.expected_signature(@timestamp, "different-nonce", @webhook_id, @secret) !=
               base

      assert Webhook.expected_signature(@timestamp, @nonce, "wh_other", @secret) != base

      assert Webhook.expected_signature(@timestamp, @nonce, @webhook_id, "different_secret") !=
               base
    end
  end

  describe "verify_signature/2" do
    test "accepts a correctly signed request, with list headers" do
      assert :ok = Webhook.verify_signature(valid_headers(), @secret)
    end

    test "accepts a correctly signed request, with map headers and mixed-case keys" do
      signature = Webhook.expected_signature(@timestamp, @nonce, @webhook_id, @secret)

      headers = %{
        "X-Timestamp" => @timestamp,
        "X-Nonce" => @nonce,
        "X-Webhook-ID" => @webhook_id,
        "X-Signature" => signature
      }

      assert :ok = Webhook.verify_signature(headers, @secret)
    end

    test "rejects a tampered signature" do
      headers =
        List.keyreplace(
          valid_headers(),
          "x-signature",
          0,
          {"x-signature", String.duplicate("0", 128)}
        )

      assert {:error, :invalid_signature} = Webhook.verify_signature(headers, @secret)
    end

    test "rejects a short/malformed signature without raising" do
      headers = List.keyreplace(valid_headers(), "x-signature", 0, {"x-signature", "deadbeef"})
      assert {:error, :invalid_signature} = Webhook.verify_signature(headers, @secret)
    end

    test "rejects an empty signature without raising" do
      headers = List.keyreplace(valid_headers(), "x-signature", 0, {"x-signature", ""})
      assert {:error, :invalid_signature} = Webhook.verify_signature(headers, @secret)
    end

    test "rejects a request signed with the wrong secret" do
      assert {:error, :invalid_signature} =
               Webhook.verify_signature(valid_headers(), "wrong_secret")
    end

    test "reports missing headers distinctly from an invalid signature" do
      assert {:error, :missing_signature_headers} = Webhook.verify_signature([], @secret)

      partial = Enum.take(valid_headers(), 2)
      assert {:error, :missing_signature_headers} = Webhook.verify_signature(partial, @secret)
    end
  end

  describe "construct_event/3" do
    test "parses a validly signed event" do
      raw_body =
        Jason.encode!(%{
          "eventID" => "evt_1",
          "type" => "account.created",
          "data" => %{"accountID" => "acct_1"},
          "createdOn" => "2026-06-23T00:00:00Z"
        })

      assert {:ok, %Event{id: "evt_1", type: "account.created", data: %{"accountID" => "acct_1"}}} =
               Webhook.construct_event(raw_body, valid_headers(), @secret)
    end

    test "rejects an event whose signature doesn't match" do
      raw_body =
        Jason.encode!(%{"eventID" => "evt_1", "type" => "account.created", "data" => %{}})

      headers = List.keyreplace(valid_headers(), "x-signature", 0, {"x-signature", "deadbeef"})

      assert {:error, :invalid_signature} = Webhook.construct_event(raw_body, headers, @secret)
    end

    test "never decodes the body before the signature has been verified" do
      # an invalid signature must short-circuit before Jason ever sees the
      # (here, deliberately malformed) body
      headers = List.keyreplace(valid_headers(), "x-signature", 0, {"x-signature", "deadbeef"})

      assert {:error, :invalid_signature} =
               Webhook.construct_event("{not valid json", headers, @secret)
    end
  end

  describe "Event.to_snake_case/1" do
    test "converts only the data payload's keys, leaving the rest of the struct alone" do
      event = %Event{
        id: "evt_1",
        type: "account.created",
        data: %{"accountID" => "acct_1"},
        created_on: "2026-06-23T00:00:00Z"
      }

      converted = Event.to_snake_case(event)

      assert converted.data == %{"account_id" => "acct_1"}
      assert converted.id == "evt_1"
      assert converted.type == "account.created"
    end
  end

  test "known_event_types/0 returns a non-empty list of documented event type strings" do
    types = Webhook.known_event_types()
    assert is_list(types)
    assert "transfer.updated" in types
    assert "dispute.created" in types
    assert Enum.all?(types, &is_binary/1)
  end
end
