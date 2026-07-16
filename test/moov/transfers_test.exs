defmodule Moov.TransfersTest do
  use ExUnit.Case, async: true

  import Moov.TestSupport

  test "create/4 automatically sets an idempotency key without being asked" do
    Req.Test.stub(__MODULE__, fn conn ->
      [key] = Plug.Conn.get_req_header(conn, "x-idempotency-key")
      Req.Test.json(conn, %{"transferID" => "tr_1", "idempotencyKeyReceived" => key})
    end)

    assert {:ok, %{"transferID" => "tr_1", "idempotencyKeyReceived" => key}} =
             Moov.Transfers.create(stub_client(__MODULE__), "acct_1", %{
               amount: %{currency: "USD", value: 100}
             })

    assert is_binary(key) and key != ""
  end

  test "create/4 lets the caller pin their own idempotency key" do
    Req.Test.stub(__MODULE__, fn conn ->
      [key] = Plug.Conn.get_req_header(conn, "x-idempotency-key")
      Req.Test.json(conn, %{"key" => key})
    end)

    assert {:ok, %{"key" => "order-42"}} =
             Moov.Transfers.create(
               stub_client(__MODULE__),
               "acct_1",
               %{amount: %{currency: "USD", value: 100}},
               idempotency_key: "order-42"
             )
  end

  test "create/4 sends X-Wait-For when requested" do
    Req.Test.stub(__MODULE__, fn conn ->
      Req.Test.json(conn, %{"waitFor" => Plug.Conn.get_req_header(conn, "x-wait-for")})
    end)

    assert {:ok, %{"waitFor" => ["rail-response"]}} =
             Moov.Transfers.create(
               stub_client(__MODULE__),
               "acct_1",
               %{amount: %{currency: "USD", value: 100}},
               wait_for: "rail-response"
             )
  end

  test "get/3 retrieves a single transfer" do
    Req.Test.stub(__MODULE__, fn conn ->
      assert conn.request_path == "/accounts/acct_1/transfers/tr_1"
      Req.Test.json(conn, %{"transferID" => "tr_1", "status" => "completed"})
    end)

    assert {:ok, %{"status" => "completed"}} =
             Moov.Transfers.get(stub_client(__MODULE__), "acct_1", "tr_1")
  end

  test "cancel/3 posts to the cancellations sub-resource" do
    Req.Test.stub(__MODULE__, fn conn ->
      assert conn.request_path == "/accounts/acct_1/transfers/tr_1/cancellations"
      assert conn.method == "POST"
      Req.Test.json(conn, %{"cancellationID" => "cancel_1"})
    end)

    assert {:ok, %{"cancellationID" => "cancel_1"}} =
             Moov.Transfers.cancel(stub_client(__MODULE__), "acct_1", "tr_1")
  end
end
