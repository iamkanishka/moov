defmodule Moov.ErrorTest do
  use ExUnit.Case, async: true

  alias Moov.Error

  describe "from_response/3" do
    test "maps known status codes to their type" do
      assert Error.from_response(400, [], nil).type == :bad_request
      assert Error.from_response(401, [], nil).type == :unauthorized
      assert Error.from_response(403, [], nil).type == :forbidden
      assert Error.from_response(404, [], nil).type == :not_found
      assert Error.from_response(409, [], nil).type == :conflict
      assert Error.from_response(422, [], nil).type == :unprocessable_entity
      assert Error.from_response(429, [], nil).type == :too_many_requests
      assert Error.from_response(500, [], nil).type == :server_error
      assert Error.from_response(502, [], nil).type == :server_error
      assert Error.from_response(503, [], nil).type == :server_error
      assert Error.from_response(504, [], nil).type == :gateway_timeout
    end

    test "falls back to :unknown for an unmapped status code" do
      assert Error.from_response(418, [], nil).type == :unknown
    end

    test "extracts the human-readable message from a body's \"error\" field" do
      error = Error.from_response(404, [], %{"error" => "account not found"})
      assert error.message == "account not found"
    end

    test "falls back to a field-level validation message when there is no \"error\" key" do
      error = Error.from_response(422, [], %{"legalBusinessName" => "is required"})
      assert error.message == "legalBusinessName: is required"
    end

    test "extracts the x-request-id header from a list of tuples, case-insensitively" do
      error = Error.from_response(500, [{"X-Request-Id", "req_abc"}], nil)
      assert error.request_id == "req_abc"
    end

    test "extracts the x-request-id header from a Req-style %{name => [values]} map" do
      error = Error.from_response(500, %{"x-request-id" => ["req_abc"]}, nil)
      assert error.request_id == "req_abc"
    end

    test "extracts retry_after_ms from a standard Retry-After header (seconds -> ms)" do
      error = Error.from_response(429, %{"retry-after" => ["2"]}, nil)
      assert error.retry_after_ms == 2_000
    end

    test "falls back to scanning the message for a millisecond hint when there's no header" do
      error = Error.from_response(422, [], %{"error" => "please retry in 1500 ms"})
      assert error.retry_after_ms == 1_500
    end

    test "recognizes the word \"milliseconds\" spelled out" do
      error = Error.from_response(422, [], %{"error" => "wait 250 milliseconds and try again"})
      assert error.retry_after_ms == 250
    end

    test "retry_after_ms is nil when there is no header and no parseable hint" do
      error = Error.from_response(429, [], %{"error" => "slow down"})
      assert error.retry_after_ms == nil
    end

    test "stores the raw decoded body" do
      body = %{"error" => "boom"}
      assert Error.from_response(500, [], body).body == body
    end
  end

  describe "from_transport_error/1" do
    test "builds a :network_error with the raw reason preserved" do
      error = Error.from_transport_error(:timeout)
      assert error.type == :network_error
      assert error.reason == :timeout
      assert error.status == nil
    end
  end

  describe "from_decode_error/2" do
    test "builds a :decode_error carrying the raw body" do
      error = Error.from_decode_error(%Jason.DecodeError{}, "not json")
      assert error.type == :decode_error
      assert error.body == "not json"
    end
  end

  describe "Exception behaviour" do
    test "message/1 includes the type, message, and request id when present" do
      error = Error.from_response(404, [{"x-request-id", "req_1"}], %{"error" => "nope"})
      assert Exception.message(error) == "Moov API error (not_found): nope [x-request-id: req_1]"
    end

    test "message/1 omits the request id segment when absent" do
      error = Error.from_response(404, [], %{"error" => "nope"})
      assert Exception.message(error) == "Moov API error (not_found): nope"
    end

    test "can be raised and rescued like any other exception" do
      error = Error.from_response(401, [], nil)

      assert_raise Moov.Error,
                   "Moov API error (unauthorized): missing or expired authentication",
                   fn ->
                     raise error
                   end
    end
  end
end
