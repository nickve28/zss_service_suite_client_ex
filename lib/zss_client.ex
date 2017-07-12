defmodule ZssClient do
  use Application

  alias ZssClient.Config

  @moduledoc """
  The interface for consumers to create ZSS Clients
  """

  @doc """
  Starts the application
  """
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(ZssClient.Client, [])
    ]

    opts = [strategy: :simple_one_for_one, name: ZssClient.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def get_config(%{identity: identity, sid: sid} = config) when is_binary(identity) and is_binary(sid) do
    Config.new(config)
  end

  def get_client(%Config{} = config) do
    Supervisor.start_child(ZssClient.Supervisor, [config])
  end
end
