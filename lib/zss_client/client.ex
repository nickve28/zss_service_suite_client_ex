defmodule ZssClient.Client do
  use GenServer

  def start_link(config) do
    GenServer.start_link(__MODULE__, [config])
  end
end
