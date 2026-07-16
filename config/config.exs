import Config

# These are intentionally left unset here. Configure your credentials in
# config/runtime.exs (or config/dev.exs / config/test.exs) so secrets never
# end up compiled into a release artifact, e.g.:
#
#     config :moov,
#       public_key: System.fetch_env!("MOOV_PUBLIC_KEY"),
#       private_key: System.fetch_env!("MOOV_PRIVATE_KEY"),
#       api_version: "v2026.04.00"
#
# See `Moov.Config` and `Moov.Client.new/1` for every available option.

if Mix.env() == :test do
  import_config "test.exs"
end
