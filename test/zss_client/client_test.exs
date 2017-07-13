defmodule ZssClient.ClientTest do
  use ExUnit.Case, async: false
  @moduledoc false

  alias ZssClient.{Client, Config}
  alias ZssClient.Mocks.Adapters.{Socket}

  doctest Client

  setup_all do
    Socket.enable

    on_exit(fn ->
      Socket.disable
    end)
  end

  test "#start_link starts a client" do
    config = %Config{sid: "SERVICE", identity: "CLIENT"}
    {:ok, pid} = Client.start_link(config)
    assert is_pid(pid) === true
    assert Process.alive?(pid) === true
  end

  test "#start_link stores the config in the state" do
    config = %Config{sid: "SERVICE", identity: "CLIENT"}
    Socket.stub(:new_socket, :my_socket)

    {:ok, pid} = Client.start_link(config)

    assert %{config: ^config} = :sys.get_state(pid)
  end

  test "#start_link stores the socket in the state" do
    config = %Config{sid: "SERVICE", identity: "CLIENT"}
    Socket.stub(:new_socket, :my_socket)

    {:ok, pid} = Client.start_link(config)

    assert %{socket: :my_socket} = :sys.get_state(pid)
  end

  test "#start_link connects the socket" do
    config = %Config{sid: "SERVICE", identity: "CLIENT"}
    this = self()

    Socket.stub(:new_socket, :my_socket)

    Socket.stub(:connect, fn socket, identity, broker ->
      assert socket === :my_socket
      assert identity === "CLIENT"
      assert broker === "tcp://127.0.0.1:7777"

      send(this, {:test, :ok})
    end)

    Client.start_link(config)

    receive do
      {:test, :ok} -> :ok
    after 2000 ->
      raise "Timeout exceeded"
    end
  end
end
