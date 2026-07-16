defmodule Moov.Retry do
  @moduledoc """
  A small, dependency-free retry-with-backoff helper.

  `Moov.Client` uses this to automatically retry requests that fail with a
  transient error: `429` (rate limited), `5xx` (Moov degraded), or a
  transport-level network error. Non-transient failures (`400`, `401`,
  `404`, `409`, `422`, decode errors, ...) are never retried, since retrying
  a request that was rejected for being invalid will just fail again.

  Delay between attempts is computed as exponential backoff with full
  jitter, capped at `:max_delay_ms` - except when Moov's response body or a
  standard `Retry-After` header tells us exactly how long to wait
  (Moov.Error.retry_after_ms/0), in which case that takes precedence.
  """

  alias Moov.Error

  @type result :: {:ok, term()} | {:error, Error.t()}

  @doc """
  Calls `fun` and, if it returns `{:error, error}` for a retryable error,
  calls it again (up to `:max_retries` additional times) with an
  exponentially increasing delay between attempts.

  ## Options

    * `:max_retries` - maximum number of *additional* attempts after the
      first one fails (default: `3`)
    * `:base_delay_ms` - base delay before the first retry (default: `250`)
    * `:max_delay_ms` - upper bound for the computed delay (default: `8_000`)
    * `:sleep_fun` - function called with the computed delay in
      milliseconds instead of `Process.sleep/1`; override this in tests so
      retry tests don't actually take seconds to run
    * `:on_retry` - a 3-arity function called with
      `(attempt_number, delay_ms, error)` before each retry, useful for
      logging or telemetry

  ## Examples

      Moov.Retry.run(fn -> do_request() end, max_retries: 3)
  """
  @spec run((-> result()), keyword()) :: result()
  def run(fun, opts \\ []) when is_function(fun, 0) do
    max_retries = Keyword.get(opts, :max_retries, 3)
    base_delay_ms = Keyword.get(opts, :base_delay_ms, 250)
    max_delay_ms = Keyword.get(opts, :max_delay_ms, 8_000)
    sleep_fun = Keyword.get(opts, :sleep_fun, &Process.sleep/1)
    on_retry = Keyword.get(opts, :on_retry, fn _attempt, _delay, _error -> :ok end)

    do_run(fun, 1, max_retries, base_delay_ms, max_delay_ms, sleep_fun, on_retry)
  end

  defp do_run(fun, attempt, max_retries, base_delay_ms, max_delay_ms, sleep_fun, on_retry) do
    case fun.() do
      {:ok, _result} = ok ->
        ok

      {:error, %Error{} = error} = err ->
        if attempt <= max_retries and retryable?(error) do
          delay = delay_ms(error, attempt, base_delay_ms, max_delay_ms)
          on_retry.(attempt, delay, error)
          sleep_fun.(delay)
          do_run(fun, attempt + 1, max_retries, base_delay_ms, max_delay_ms, sleep_fun, on_retry)
        else
          err
        end
    end
  end

  @doc """
  Whether the given `Moov.Error` represents a transient failure worth
  retrying.
  """
  @spec retryable?(Error.t()) :: boolean()
  def retryable?(%Error{type: type}) do
    type in [:too_many_requests, :server_error, :gateway_timeout, :network_error]
  end

  @doc """
  Computes the delay (in milliseconds) before the next attempt.

  Prefers an explicit `retry_after_ms` from the error (Moov told us exactly
  how long to wait) and otherwise falls back to exponential backoff with
  full jitter: a random value between `0` and
  `min(base_delay_ms * 2^(attempt - 1), max_delay_ms)`.
  """
  @spec delay_ms(Error.t(), pos_integer(), pos_integer(), pos_integer()) :: non_neg_integer()
  def delay_ms(%Error{retry_after_ms: ms}, _attempt, _base_delay_ms, _max_delay_ms)
      when is_integer(ms) and ms >= 0 do
    ms
  end

  def delay_ms(_error, attempt, base_delay_ms, max_delay_ms) do
    capped = min(base_delay_ms * Integer.pow(2, attempt - 1), max_delay_ms)
    :rand.uniform(capped + 1) - 1
  end
end
