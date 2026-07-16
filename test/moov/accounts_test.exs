defmodule Moov.AccountsTest do
  use ExUnit.Case, async: true

  import Moov.TestSupport

  test "create/2 posts to /accounts with a camelCased body" do
    Req.Test.stub(__MODULE__, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/accounts"
      {:ok, raw_body, conn} = Plug.Conn.read_body(conn)
      assert Jason.decode!(raw_body) == %{"accountType" => "individual"}
      Req.Test.json(conn, %{"accountID" => "acct_1", "accountType" => "individual"})
    end)

    assert {:ok, %{"accountID" => "acct_1"}} =
             Moov.Accounts.create(stub_client(__MODULE__), %{account_type: "individual"})
  end

  test "get/2 issues a GET to /accounts/:id" do
    Req.Test.stub(__MODULE__, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/accounts/acct_1"
      Req.Test.json(conn, %{"accountID" => "acct_1"})
    end)

    assert {:ok, %{"accountID" => "acct_1"}} =
             Moov.Accounts.get(stub_client(__MODULE__), "acct_1")
  end

  test "list/2 forwards query options" do
    Req.Test.stub(__MODULE__, fn conn ->
      assert conn.request_path == "/accounts"
      assert conn.query_string =~ "type=individual"
      Req.Test.json(conn, [%{"accountID" => "acct_1"}])
    end)

    assert {:ok, [%{"accountID" => "acct_1"}]} =
             Moov.Accounts.list(stub_client(__MODULE__), query: [type: "individual"])
  end

  test "update/3 sends a PATCH" do
    Req.Test.stub(__MODULE__, fn conn ->
      assert conn.method == "PATCH"
      Req.Test.json(conn, %{"accountID" => "acct_1"})
    end)

    assert {:ok, _} = Moov.Accounts.update(stub_client(__MODULE__), "acct_1", %{profile: %{}})
  end

  test "delete/2 sends a DELETE" do
    Req.Test.stub(__MODULE__, fn conn ->
      assert conn.method == "DELETE"
      Plug.Conn.send_resp(conn, 204, "")
    end)

    assert {:ok, _} = Moov.Accounts.delete(stub_client(__MODULE__), "acct_1")
  end
end
