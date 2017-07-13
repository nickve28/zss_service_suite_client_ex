defmodule ZssClient.Mocks.Socket do
  @moduledoc false

  @behaviour ZssClient.Sender

  use GenServer

  defmodule State do
    defstruct [
      state: :disabled,
      handlers: %{}
    ]
  end

  def start do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_), do: {:ok, %State{}}

  def enable do
    GenServer.call(__MODULE__, :enable)
  end

  def disable do
    GenServer.call(__MODULE__, :disable)
  end

  def stub(verb, response) when is_atom(verb) do
    GenServer.call(__MODULE__, {:stub, verb, response})
  end

  def restore(verb) do
    GenServer.call(__MODULE__, {:restore, verb})
  end

  #Simulate functions
  def new(config), do: GenServer.call(__MODULE__, {:new, [config]})

  def connect(socket, identity, broker) do
    GenServer.call(__MODULE__, {:connect, [socket], identity, broker})
  end

  def get_response(socket), do: GenServer.call(__MODULE__, {:get_response, [socket]})

  def send(socket, msg), do: GenServer.call(__MODULE__, {:send, [socket, msg]})

  def cleanup(socket), do: GenServer.call(__MODULE__, {:cleanup, [socket]})

  def handle_call({:stub, verb, response}, _from, %State{handlers: handlers} = state) do
    handlers = Map.put(handlers, verb, response)
    {:reply, :ok, %State{state | handlers: handlers}}
  end

  def handle_call({:restore, verb}, _from, %State{handlers: handlers} = state) do
    handlers = Map.drop(handlers, [verb])
    {:reply, :ok, %State{state | handlers: handlers}}
  end

  def handle_call(:enable, _from, state) do
    new_state = %State{state | state: :enabled}
    {:reply, :ok, new_state}
  end

  def handle_call(:disable, _from, state) do
    new_state = %State{state | state: :disabled}
    {:reply, :ok, new_state}
  end

  def handle_call({verb, args}, _from, %{state: :enabled, handlers: handlers} = state) do
    response = handlers
    |> Map.get(verb, :ok) #default to :ok
    |> case do
      f when is_function(f) -> apply(f, args)
      stub -> stub
    end
    {:reply, response, state}
  end

  def handle_call({fun_name, args}, _from, %{state: :disabled} = state) do
    response = apply(ZssService.Adapters.Socket, fun_name, args)
    {:reply, response, state}
  end
end
