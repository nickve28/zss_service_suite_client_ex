defmodule ZssClient.ClientTest do
  use ExUnit.Case, async: false
  @moduledoc false

  alias ZssClient.{Client, Config, Message}
  alias ZssClient.Mocks.Adapters.{Socket}

  doctest Client

  setup_all do
    Socket.enable

    on_exit(fn ->
      Socket.disable
    end)
  end

  describe "#start_link" do

    test "starts a client" do
      config = %Config{sid: "SERVICE", identity: "CLIENT"}
      {:ok, pid} = Client.start_link(config)
      assert is_pid(pid) === true
      assert Process.alive?(pid) === true
    end

    test "stores the config in the state" do
      config = %Config{sid: "SERVICE", identity: "CLIENT"}
      Socket.stub(:new_socket, :my_socket)

      {:ok, pid} = Client.start_link(config)

      assert %{config: ^config} = :sys.get_state(pid)
    end

    test "stores the socket in the state" do
      config = %Config{sid: "SERVICE", identity: "CLIENT"}
      Socket.stub(:new_socket, :my_socket)

      {:ok, pid} = Client.start_link(config)

      assert %{socket: :my_socket} = :sys.get_state(pid)
    end

    test "connects the socket" do
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

  describe "#call" do
    test "sends a message to the broker" do
      config = %Config{sid: "SERVICE", identity: "CLIENT"}
      this = self()

      Socket.stub(:new_socket, :my_socket)
      Socket.stub(:connect, :ok)
      Socket.stub(:send, fn socket, message ->
        assert socket === :my_socket
        assert is_list(message) === true

        send(this, {:test, :ok})
      end)

      {:ok, client} = Client.start_link(config)
      Client.call(client, {"get", %{}, %{}})

      receive do
        {:test, :ok} -> :ok
      after 2000 ->
        raise "Timeout exceeded"
      end
    end

    test "The frames sent should be directed to the correct service" do
      config = %Config{sid: "SERVICE", identity: "CLIENT"}
      this = self()

      Socket.stub(:new_socket, :my_socket)
      Socket.stub(:connect, :ok)
      Socket.stub(:send, fn _, frames ->
        [_, "REQ", _rid, address | _] = frames
        assert %{"sid" => "SERVICE", "verb" => "GET"} = Msgpax.unpack!(address)

        send(this, {:test, :ok})
      end)

      {:ok, client} = Client.start_link(config)
      Client.call(client, {"get", %{}, %{}})

      receive do
        {:test, :ok} -> :ok
      after 2000 ->
        raise "Timeout exceeded"
      end
    end

    test "The frames sent should exclude the identity" do
      config = %Config{sid: "SERVICE", identity: "CLIENT"}
      this = self()

      Socket.stub(:new_socket, :my_socket)
      Socket.stub(:connect, :ok)
      Socket.stub(:send, fn _, frames ->
        assert Enum.count(frames) === 7

        send(this, {:test, :ok})
      end)

      {:ok, client} = Client.start_link(config)
      Client.call(client, {"get", %{}, %{}})

      receive do
        {:test, :ok} -> :ok
      after 2000 ->
        raise "Timeout exceeded"
      end
    end

    test "the frames sent should include the proper payload" do
      config = %Config{sid: "SERVICE", identity: "CLIENT"}
      this = self()

      Socket.stub(:new_socket, :my_socket)
      Socket.stub(:connect, :ok)
      Socket.stub(:send, fn _, frames ->
        [payload | _] = frames |> Enum.reverse
        assert %{"foo" => "bar"} === Msgpax.unpack!(payload)

        send(this, {:test, :ok})
      end)

      {:ok, client} = Client.start_link(config)
      Client.call(client, {"get", %{"foo" => "bar"}, %{"user_id" => "1"}})

      receive do
        {:test, :ok} -> :ok
      after 2000 ->
        raise "Timeout exceeded"
      end
    end

    test "the frames sent should include the proper headers" do
      config = %Config{sid: "SERVICE", identity: "CLIENT"}
      this = self()

      Socket.stub(:new_socket, :my_socket)
      Socket.stub(:connect, :ok)
      Socket.stub(:send, fn _, frames ->
        [_, "REQ", _rid, _address, headers | _] = frames
        assert %{"headers" => %{"user_id" => "1"}} = Msgpax.unpack!(headers)

        send(this, {:test, :ok})
      end)

      {:ok, client} = Client.start_link(config)
      headers = %{headers: %{"user_id" => "1"}}
      Client.call(client, {"get", %{"foo" => "bar"}, headers})

      receive do
        {:test, :ok} -> :ok
      after 2000 ->
        raise "Timeout exceeded"
      end
    end
  end

  describe "#get_response" do
    test "formats the received message in a correct format response" do
      config = %Config{sid: "SERVICE", identity: "CLIENT"}

      Socket.stub(:new_socket, :my_socket)
      Socket.stub(:connect, :ok)
      Socket.stub(:send, :ok)
      Socket.stub(:get_response, fn _ ->
        response = Message.new "SERVICE", "GET"
        response = %Message{response | status: "200", payload: %{"id" => "1"}, type: "REP"}

        {:ok, response |> Message.to_frames}
      end)

      {:ok, client} = Client.start_link(config)
      headers = %{headers: %{"user_id" => "1"}}
      Client.call(client, {"get", %{"foo" => "bar"}, headers})

      response = Client.get_response(client)
      assert {:ok, %{"id" => "1"}, 200} === response
    end
  end
end
