defmodule Moov.FilesTest do
  use ExUnit.Case, async: true

  import Moov.TestSupport

  test "upload/4 sends a multipart/form-data request with the file" do
    Req.Test.stub(__MODULE__, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/accounts/acct_1/files"
      [content_type] = Plug.Conn.get_req_header(conn, "content-type")
      assert content_type =~ "multipart/form-data"

      opts = Plug.Parsers.init(parsers: [{Plug.Parsers.MULTIPART, []}])
      conn = Plug.Parsers.call(conn, opts)

      assert %Plug.Upload{filename: "id.png", content_type: "image/png"} = conn.params["file"]

      Req.Test.json(conn, %{"fileID" => "file_1"})
    end)

    assert {:ok, %{"fileID" => "file_1"}} =
             Moov.Files.upload(stub_client(__MODULE__), "acct_1", "fake-png-bytes",
               filename: "id.png",
               content_type: "image/png"
             )
  end

  test "list/3 lists files for an account" do
    Req.Test.stub(__MODULE__, fn conn ->
      assert conn.request_path == "/accounts/acct_1/files"
      assert conn.method == "GET"
      Req.Test.json(conn, [%{"fileID" => "file_1"}])
    end)

    assert {:ok, [%{"fileID" => "file_1"}]} = Moov.Files.list(stub_client(__MODULE__), "acct_1")
  end
end
