defmodule ZssClient.Config do
  @moduledoc """
  A struct to house the configuration of a client
  """

  alias ZssClient.Config

  defstruct [
    identity: nil,
    broker: "tcp://127.0.0.1",
    timeout: 1000,
    sid: nil
  ]

  def new(%{identity: identity, sid: sid} = config) do
    full_config = %{config |
      identity: String.upcase(identity),
      sid: String.upcase(sid)
    }

    %Config{}
    |> Map.merge(full_config)
  end
end