use Mix.Config

config :logger,
  backends: [:console],
  compile_time_purge_level: :info

config :zss_client,
  socket_adapter: ZssClient.Mocks.Adapters.Socket
