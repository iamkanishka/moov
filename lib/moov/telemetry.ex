defmodule Moov.Telemetry do
  @moduledoc """
  Telemetry events emitted by this library, via the
  [`:telemetry`](https://hexdocs.pm/telemetry) library (a transitive
  dependency of `Req`, so nothing extra to install).

  ## `[:moov, :request, :start]`

  Emitted right before a request is sent (on every attempt, including
  retries).

  | measurement    | description                              |
  |----------------|-------------------------------------------|
  | `:system_time` | `System.system_time/0` when emitted       |

  | metadata   | description                                   |
  |------------|------------------------------------------------|
  | `:method`  | the HTTP method, e.g. `:post`                  |
  | `:path`    | the request path, e.g. `"/accounts"`           |
  | `:attempt` | which attempt this is, starting at `1`         |

  ## `[:moov, :request, :stop]`

  Emitted after a request (successfully or not) finishes its *final*
  attempt - i.e. once, per logical call, after all retries are exhausted.

  | measurement | description                                |
  |-------------|---------------------------------------------|
  | `:duration` | total time across all attempts, in `:native` units |

  | metadata     | description                                          |
  |--------------|-------------------------------------------------------|
  | `:method`    | the HTTP method                                      |
  | `:path`      | the request path                                     |
  | `:status`    | the HTTP status code, if a response was received     |
  | `:error_type`| the `t:Moov.Error.type/0` atom, if the call failed    |
  | `:attempts`  | how many attempts were made in total                 |

  ## `[:moov, :request, :exception]`

  Emitted instead of `:stop` if building or sending the request raises.

  ## `[:moov, :retry]`

  Emitted once per retry, right before sleeping.

  | measurement | description                            |
  |-------------|------------------------------------------|
  | `:delay_ms` | how long this attempt will sleep before retrying |

  | metadata    | description                                |
  |-------------|----------------------------------------------|
  | `:method`   | the HTTP method                             |
  | `:path`     | the request path                            |
  | `:attempt`  | the attempt number that just failed          |
  | `:error`    | the `Moov.Error` that triggered the retry    |

  ## Example attach call

      :telemetry.attach(
        "log-moov-requests",
        [:moov, :request, :stop],
        fn _event, %{duration: duration}, metadata, _config ->
          Logger.info("Moov \#{metadata.method} \#{metadata.path} -> " <>
            "\#{inspect(metadata.status || metadata.error_type)} in " <>
            "\#{System.convert_time_unit(duration, :native, :millisecond)}ms")
        end,
        nil
      )
  """

  @doc false
  @spec span(map(), (-> {term(), map()})) :: term()
  def span(metadata, fun) when is_map(metadata) or is_list(metadata) do
    :telemetry.span([:moov, :request], Map.new(metadata), fun)
  end

  @doc false
  @spec retry(%{required(:delay_ms) => non_neg_integer()}) :: :ok
  def retry(metadata) do
    :telemetry.execute([:moov, :retry], %{delay_ms: metadata.delay_ms}, metadata)
  end
end
