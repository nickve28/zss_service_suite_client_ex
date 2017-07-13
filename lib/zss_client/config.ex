defmodule ZssClient.Config do
  @moduledoc """
  A struct to house the configuration of a client
  """

  alias ZssClient.Config

  defstruct [
    identity: nil,
    broker: "tcp://127.0.0.1:7777",
    timeout: 1000,
    sid: nil
  ]

  @doc """
  Creates a new configuration with sensible defaults. Used to create ZSS Clients.
  """
  def new(%{identity: identity, sid: sid} = config) do
    full_config = %{config |
      identity: String.upcase(identity),
      sid: String.upcase(sid)
    }

    %Config{}
    |> Map.merge(full_config)
  end
end
