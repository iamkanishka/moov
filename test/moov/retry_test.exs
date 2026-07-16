defmodule Moov.RetryTest do
  use ExUnit.Case, async: true

  alias Moov.{Error, Retry}

  describe "retryable?/1" do
    test "transient error types are retryable" do
      for type <- [:too_many_requests, :server_error, :gateway_timeout, :network_error] do
        assert Retry.retryable?(%Error{type: type})
      end
    end

    test "non-transient error types are not retryable" do
      for type <- [
            :bad_request,
            :unauthorized,
            :forbidden,
            :not_found,
            :conflict,
            :unprocessable_entity,
            :decode_error,
            :unknown
          ] do
        refute Retry.retryable?(%Error{type: type})
      end
    end
  end

  describe "run/2" do
    test "returns immediately on success without sleeping" do
      result = Retry.run(fn -> {:ok, :done} end, sleep_fun: fn _ -> flunk("should not sleep") end)
      assert result == {:ok, :done}
    end

    test "does not retry a non-retryable error" do
      {:ok, calls} = Agent.start_link(fn -> 0 end)

      result =
        Retry.run(
          fn ->
            Agent.update(calls, &(&1 + 1))
            {:error, %Error{type: :unprocessable_entity}}
          end,
          max_retries: 5,
          sleep_fun: fn _ -> flunk("should not sleep") end
        )

      assert {:error, %Error{type: :unprocessable_entity}} = result
      assert Agent.get(calls, & &1) == 1
    end

    test "retries a retryable error up to max_retries, then gives up" do
      {:ok, calls} = Agent.start_link(fn -> 0 end)
      {:ok, sleeps} = Agent.start_link(fn -> [] end)

      result =
        Retry.run(
          fn ->
            Agent.update(calls, &(&1 + 1))
            {:error, %Error{type: :server_error}}
          end,
          max_retries: 3,
          sleep_fun: fn ms -> Agent.update(sleeps, &[ms | &1]) end
        )

      assert {:error, %Error{type: :server_error}} = result
      # 1 initial attempt + 3 retries = 4 total calls
      assert Agent.get(calls, & &1) == 4
      assert length(Agent.get(sleeps, & &1)) == 3
    end

    test "stops retrying as soon as a call succeeds" do
      {:ok, calls} = Agent.start_link(fn -> 0 end)

      result =
        Retry.run(
          fn ->
            n = Agent.get_and_update(calls, &{&1, &1 + 1})
            if n < 2, do: {:error, %Error{type: :server_error}}, else: {:ok, :recovered}
          end,
          max_retries: 5,
          sleep_fun: fn _ -> :ok end
        )

      assert result == {:ok, :recovered}
      assert Agent.get(calls, & &1) == 3
    end

    test "calls on_retry with the attempt number and computed delay before sleeping" do
      {:ok, retries} = Agent.start_link(fn -> [] end)
      {:ok, calls} = Agent.start_link(fn -> 0 end)

      Retry.run(
        fn ->
          n = Agent.get_and_update(calls, &{&1, &1 + 1})
          if n < 1, do: {:error, %Error{type: :server_error}}, else: {:ok, :done}
        end,
        max_retries: 3,
        sleep_fun: fn _ -> :ok end,
        on_retry: fn attempt, delay, error ->
          Agent.update(retries, &[{attempt, delay, error.type} | &1])
        end
      )

      assert [{1, delay, :server_error}] = Agent.get(retries, & &1)
      assert is_integer(delay) and delay >= 0
    end
  end

  describe "delay_ms/4" do
    test "prefers an explicit retry_after_ms over computed backoff" do
      error = %Error{retry_after_ms: 5_000}
      assert Retry.delay_ms(error, 1, 250, 8_000) == 5_000
      assert Retry.delay_ms(error, 10, 250, 8_000) == 5_000
    end

    test "computed backoff is bounded between 0 and the capped exponential value" do
      error = %Error{retry_after_ms: nil}

      for attempt <- 1..6 do
        cap = min(250 * Integer.pow(2, attempt - 1), 8_000)
        delay = Retry.delay_ms(error, attempt, 250, 8_000)
        assert delay >= 0 and delay <= cap
      end
    end

    test "computed backoff never exceeds max_delay_ms even for large attempt numbers" do
      error = %Error{retry_after_ms: nil}
      delay = Retry.delay_ms(error, 20, 250, 8_000)
      assert delay <= 8_000
    end
  end
end
