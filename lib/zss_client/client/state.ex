defmodule ZssClient.Client.State do
  @moduledoc """
  Provides the state struct for the client
  """
  defstruct [
    socket: nil,
    config: nil,
    identity: nil
  ]

  @doc """
  Create a new state, passing the config and socket
  """
  def new(config, identity, socket) do
    %ZssClient.Client.State{
      config: config,
      socket: socket,
      identity: identity
    }
  end
end
