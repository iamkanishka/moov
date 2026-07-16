defmodule Moov.ClientTest do
  use ExUnit.Case, async: true

  import Moov.TestSupport

  alias Moov.Client

  describe "new/1" do
    test "builds Basic Auth from public_key/private_key" do
      client = Client.new(public_key: "pub", private_key: "priv")
      assert client.auth == {:basic, "pub", "priv"}
    end

    test "prefers a bearer access_token over public/private key when both are given" do
      client = Client.new(public_key: "pub", private_key: "priv", access_token: "tok_123")
      assert client.auth == {:bearer, "tok_123"}
    end

    test "auth is nil when no credentials are configured" do
      client = Client.new(public_key: nil, private_key: nil, access_token: nil)
      assert client.auth == nil
    end

    test "applies sensible defaults" do
      client = Client.new(public_key: "pub", private_key: "priv")
      assert client.base_url == "https://api.moov.io"
      assert is_binary(client.api_version)
      assert client.max_retries >= 0
    end
  end

  describe "request/4 - happy path" do
    test "GET returns {:ok, body} on a 2xx response" do
      Req.Test.stub(__MODULE__, fn conn ->
        Req.Test.json(conn, %{"accountID" => "acct_1"})
      end)

      assert {:ok, %{"accountID" => "acct_1"}} =
               Client.get(stub_client(__MODULE__), "/accounts/acct_1")
    end

    test "sends the X-Moov-Version header" do
      Req.Test.stub(__MODULE__, fn conn ->
        [version] = Plug.Conn.get_req_header(conn, "x-moov-version")
        Req.Test.json(conn, %{"version" => version})
      end)

      assert {:ok, %{"version" => "v2026.04.00"}} =
               Client.get(stub_client(__MODULE__, api_version: "v2026.04.00"), "/ping")
    end

    test "sends a Basic Authorization header built from public_key/private_key" do
      Req.Test.stub(__MODULE__, fn conn ->
        [auth] = Plug.Conn.get_req_header(conn, "authorization")
        Req.Test.json(conn, %{"auth" => auth})
      end)

      client = stub_client(__MODULE__, public_key: "pub_123", private_key: "priv_456")
      assert {:ok, %{"auth" => auth}} = Client.get(client, "/ping")
      assert auth == "Basic " <> Base.encode64("pub_123:priv_456")
    end

    test "sends a Bearer Authorization header when configured with an access token" do
      Req.Test.stub(__MODULE__, fn conn ->
        [auth] = Plug.Conn.get_req_header(conn, "authorization")
        Req.Test.json(conn, %{"auth" => auth})
      end)

      client = stub_client(__MODULE__, public_key: nil, private_key: nil, access_token: "tok_abc")
      assert {:ok, %{"auth" => "Bearer tok_abc"}} = Client.get(client, "/ping")
    end

    test "camelCases the JSON request body" do
      Req.Test.stub(__MODULE__, fn conn ->
        {:ok, raw_body, conn} = Plug.Conn.read_body(conn)
        Req.Test.json(conn, Jason.decode!(raw_body))
      end)

      client = stub_client(__MODULE__)

      assert {:ok, %{"legalBusinessName" => "Acme"}} =
               Client.post(client, "/accounts", %{legal_business_name: "Acme"})
    end

    test "camelCases query string parameters" do
      Req.Test.stub(__MODULE__, fn conn ->
        Req.Test.json(conn, %{"query" => conn.query_string})
      end)

      client = stub_client(__MODULE__)

      assert {:ok, %{"query" => query}} =
               Client.get(client, "/accounts", query: [include_disabled: true])

      assert query =~ "includeDisabled=true"
    end

    test "sends the X-Wait-For header when :wait_for is given" do
      Req.Test.stub(__MODULE__, fn conn ->
        Req.Test.json(conn, %{"waitFor" => Plug.Conn.get_req_header(conn, "x-wait-for")})
      end)

      client = stub_client(__MODULE__)

      assert {:ok, %{"waitFor" => ["rail-response"]}} =
               Client.post(client, "/x", %{}, wait_for: "rail-response")
    end
  end

  describe "request/4 - idempotency" do
    test "generates an X-Idempotency-Key when :idempotent is true and none is given" do
      Req.Test.stub(__MODULE__, fn conn ->
        [key] = Plug.Conn.get_req_header(conn, "x-idempotency-key")
        Req.Test.json(conn, %{"key" => key})
      end)

      client = stub_client(__MODULE__)

      assert {:ok, %{"key" => key}} =
               Client.request(client, :post, "/x", json: %{}, idempotent: true)

      assert is_binary(key) and key != ""
    end

    test "uses an explicit :idempotency_key verbatim, without generating one" do
      Req.Test.stub(__MODULE__, fn conn ->
        [key] = Plug.Conn.get_req_header(conn, "x-idempotency-key")
        Req.Test.json(conn, %{"key" => key})
      end)

      client = stub_client(__MODULE__)

      assert {:ok, %{"key" => "my-own-key-123"}} =
               Client.request(client, :post, "/x", json: %{}, idempotency_key: "my-own-key-123")
    end

    test "reuses the same idempotency key across every retry attempt" do
      {:ok, keys} = Agent.start_link(fn -> [] end)
      {:ok, attempts} = Agent.start_link(fn -> 0 end)

      Req.Test.stub(__MODULE__, fn conn ->
        [key] = Plug.Conn.get_req_header(conn, "x-idempotency-key")
        Agent.update(keys, &[key | &1])
        n = Agent.get_and_update(attempts, &{&1, &1 + 1})

        if n < 2 do
          conn |> Plug.Conn.put_status(503) |> Req.Test.json(%{"error" => "unavailable"})
        else
          Req.Test.json(conn, %{"ok" => true})
        end
      end)

      client =
        stub_client(__MODULE__, max_retries: 3, req_options: [plug: {Req.Test, __MODULE__}])

      assert {:ok, %{"ok" => true}} =
               Client.request(client, :post, "/accounts/acct_1/transfers",
                 json: %{},
                 idempotent: true,
                 max_retries: 3
               )

      recorded = Agent.get(keys, & &1)
      assert length(recorded) == 3
      assert length(Enum.uniq(recorded)) == 1
    end
  end

  describe "request/4 - error mapping" do
    test "maps a non-2xx response to {:error, %Moov.Error{}} with status and request id" do
      Req.Test.stub(__MODULE__, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("x-request-id", "req_xyz")
        |> Plug.Conn.put_status(404)
        |> Req.Test.json(%{"error" => "account not found"})
      end)

      assert {:error,
              %Moov.Error{
                type: :not_found,
                status: 404,
                request_id: "req_xyz",
                message: "account not found"
              }} = Client.get(stub_client(__MODULE__), "/accounts/missing")
    end

    test "does not retry a 422 and returns the validation error" do
      {:ok, calls} = Agent.start_link(fn -> 0 end)

      Req.Test.stub(__MODULE__, fn conn ->
        Agent.update(calls, &(&1 + 1))

        conn
        |> Plug.Conn.put_status(422)
        |> Req.Test.json(%{"error" => "amount must be positive"})
      end)

      client = stub_client(__MODULE__, max_retries: 5)
      assert {:error, %Moov.Error{type: :unprocessable_entity}} = Client.post(client, "/x", %{})
      assert Agent.get(calls, & &1) == 1
    end

    test "retries a 503 up to max_retries and then surfaces the error" do
      {:ok, calls} = Agent.start_link(fn -> 0 end)

      Req.Test.stub(__MODULE__, fn conn ->
        Agent.update(calls, &(&1 + 1))
        conn |> Plug.Conn.put_status(503) |> Req.Test.json(%{"error" => "unavailable"})
      end)

      client = stub_client(__MODULE__, max_retries: 2)
      assert {:error, %Moov.Error{type: :server_error}} = Client.get(client, "/x")
      assert Agent.get(calls, & &1) == 3
    end

    test "maps a transport-level failure to a :network_error" do
      Req.Test.stub(__MODULE__, fn conn -> Req.Test.transport_error(conn, :timeout) end)

      client = stub_client(__MODULE__, max_retries: 0)

      assert {:error, %Moov.Error{type: :network_error, reason: :timeout}} =
               Client.get(client, "/x")
    end
  end
end
