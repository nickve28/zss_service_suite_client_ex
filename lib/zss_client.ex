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

  @doc """
  Create a configuration for clients, based on the provided map arguments

  Arguments:\n
  identity: The identity of the client. eg: MY_CLIENT
  sid: The service identifier to which this client should talk.

  returns a config struct.
  """
  def get_config(%{identity: identity, sid: sid} = config) when is_binary(identity) and is_binary(sid) do
    Config.new(config)
  end

  @doc """
  Create a client instance based on the provided config struct.

  returns {:ok, pid}
  """
  def get_client(%Config{} = config) do
    Supervisor.start_child(ZssClient.Supervisor, [config])
  end
end
