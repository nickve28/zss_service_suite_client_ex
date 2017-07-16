defmodule ZssClient.Client do
  @moduledoc """
  The client interface for ZSS.

  Use to instantiate clients and call endpoints
  """

  alias ZssClient.Client.{State}
  alias ZssClient.Adapters.{Socket}
  alias ZssClient.{Message}
  import ZssClient.Error

  require Logger

  use GenServer

  @socket Application.get_env(:zss_client, :socket_adapter) || Socket

  # Public API
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
    socket = @socket.new_socket(opts)

    @socket.connect(socket, config.identity, config.broker)

    state = State.new(config, identity, socket)
    {:ok, state}
  end

  def handle_call({:call, {verb, payload, options}}, _from, %{config: config} = state) do
    headers = Map.get(options, :headers, nil) || Map.get(options, "headers", %{})

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
    |> @socket.get_response

    response = Message.parse(frames)

    Logger.info("Received reply from #{response.address.sid} with status #{response.status}")

    Logger.debug(fn ->
      "Received payload #{inspect response.payload}"
    end)

    Logger.debug(fn ->
      "Received headers #{inspect response.headers}"
    end)

    %{payload: payload, status: status} = response
    code = status |> String.to_integer

    indicator = case error?(code) do
      true -> :error
      _ -> :ok
    end

    reply_payload = case error?(code) do
      true -> get_error(code, payload)
        _ -> payload
    end

    reply = {indicator, reply_payload, code}

    {:reply, reply, state}
  end

  # Private API

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
    @socket.send(socket, frames)
  end
end
