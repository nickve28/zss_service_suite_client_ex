defmodule ZssClient.Client do
  @moduledoc """
  The client interface for ZSS.

  Use to instantiate clients and call endpoints
  """

  alias ZssClient.Client.Implementation, as: Client

  def start_link(config) do
    GenServer.start_link(Client, [config])
  end

  @doc """
  Make a call to a service, with the provided payload and options
  """
  def call(pid, {verb, payload, options}) when is_map(options) do
    GenServer.call(pid, {:call, {verb |> String.upcase, payload, options}})
  end

  def get_response(pid) do
    GenServer.call(pid, :get_response)
  end
end
