defmodule ZssClient.Client do
  @moduledoc """
  The client interface for ZSS.

  Use to instantiate clients and call endpoints
  """

  alias ZssClient.Client.{State}
  alias ZssClient.Adapters.{Socket}
  alias ZssClient.{Message}

  require Logger

  use GenServer

  def start_link(config) do
    GenServer.start_link(__MODULE__, [config])
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

  # Genserver API
  def init([config]) do
    identity = get_identity(config.identity)
    opts = %{type: :dealer, identity: identity}
    socket = Socket.new_socket(opts)
    Socket.connect(socket, config.identity, config.broker)

    state = State.new(config, identity, socket)
    {:ok, state}
  end

  def handle_call({:call, {verb, payload, options}}, _from, %{config: config} = state) do
    headers = Map.take(options, [:headers])

    message = Message.new config.sid, verb
    message = %ZssClient.Message{message | payload: payload, headers: headers}

    Logger.info("#{config.identity}: Sending message to #{message.address.sid} with timeout #{config.timeout}")

    Logger.debug(fn ->
      "Sending payload #{inspect message.payload}"
    end)
    Logger.debug(fn ->
      "Sending headers #{inspect message.headers}"
    end)

    feedback = send_message(state.socket, message)
    {:reply, feedback, state}
  end

  def handle_call(:get_response, _from, state) do
    {:ok, frames} = state.socket
    |> Socket.get_response

    response = Message.parse(frames)

    Logger.info("Received reply from #{response.address.sid} with status #{response.status}")

    Logger.debug(fn ->
      "Received payload #{inspect response.payload}"
    end)

    Logger.debug(fn ->
      "Received headers #{inspect response.headers}"
    end)

    %{payload: payload, status: status} = response

    {:reply, {:ok, payload, status}, state}
  end

  @doc """
  Create an unique identity for this client
  """
  defp get_identity(sid) do
    "#{sid}##{UUID.uuid1()}"
  end

  @doc """
  Sends a message to the specified service

  Note that the identity frame (first frame) is removed.
  This is due to dealer requests appending this themselves.
  """
  defp send_message(socket, message) do
    [_ | frames] = Message.to_frames(message)
    Socket.send(socket, frames)
  end
end
