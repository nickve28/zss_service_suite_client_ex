use Mix.Config

config :logger,
  backends: [:console],
  compile_time_purge_level: :debug

config :zss_client,
  socket_adapter: ZssClient.Adapters.Socket

if MIX_ENV === :test do
  import_config "#{Mix.env}.exs"
end
