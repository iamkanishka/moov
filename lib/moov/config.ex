defmodule Moov.Config do
  @moduledoc """
  Resolves default configuration for `Moov.Client.new/1` from application
  environment, with sane fallbacks.

  Set any of these in your `config/runtime.exs`:

      config :moov,
        public_key: System.get_env("MOOV_PUBLIC_KEY"),
        private_key: System.get_env("MOOV_PRIVATE_KEY"),
        access_token: nil,
        api_version: "v2026.04.00",
        base_url: "https://api.moov.io",
        max_retries: 3,
        receive_timeout: 30_000

  None of this is required - every option can also be passed directly to
  `Moov.Client.new/1`, which always takes precedence over application
  environment. This module exists purely so you *can* configure a default
  client once via config and call `Moov.Client.new()` everywhere else.
  """

  @default_base_url "https://api.moov.io"
  @default_api_version "v2026.04.00"
  @default_max_retries 3
  @default_receive_timeout 30_000

  @doc false
  @spec resolve(keyword()) :: keyword()
  def resolve(overrides) when is_list(overrides) do
    [
      base_url: get(:base_url, @default_base_url),
      api_version: get(:api_version, @default_api_version),
      public_key: get(:public_key, nil),
      private_key: get(:private_key, nil),
      access_token: get(:access_token, nil),
      max_retries: get(:max_retries, @default_max_retries),
      receive_timeout: get(:receive_timeout, @default_receive_timeout),
      req_options: get(:req_options, [])
    ]
    |> Keyword.merge(overrides)
  end

  defp get(key, default), do: Application.get_env(:moov, key, default)
end
