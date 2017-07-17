defmodule ZssClient.Client.Implementation do
  @moduledoc "Implementation for client genserver"

  use GenServer

  alias ZssClient.Client.{State}
  alias ZssClient.Adapters.{Socket}
  alias ZssClient.{Message}
  import ZssClient.Error

  require Logger

  @socket Application.get_env(:zss_client, :socket_adapter) || Socket

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

  def handle_call(:get_response, _from, %{config: %{timeout: timeout}} = state) do
    task = Task.async(fn ->
      state.socket
      |> @socket.get_response
    end)

    # https://hexdocs.pm/elixir/Task.html#yield/2
    reply = case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, {:ok, frames}} ->
        handle_success(frames |> Message.parse)
      _ ->
        Logger.info("REP ended up in a timeout after #{timeout}ms!")
        {:error, get_error(599), 599}
    end

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

  @doc """
  Success handler for client
  """
  defp handle_success(message) do
    Logger.info("Received reply from #{message.address.sid} with status #{message.status}")

    Logger.debug(fn ->
      "Received payload #{inspect message.payload}"
    end)

    Logger.debug(fn ->
      "Received headers #{inspect message.headers}"
    end)

    %{payload: payload, status: status} = message
    code = status |> String.to_integer

    indicator = case error?(code) do
      true -> :error
      _ -> :ok
    end

    reply_payload = case error?(code) do
      true -> get_error(code, payload)
        _ -> payload
    end

    {indicator, reply_payload, code}
  end
end
