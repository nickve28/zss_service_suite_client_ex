defmodule ZssClient.ConfigTest do
  @moduledoc false

  use ExUnit.Case

  alias ZssClient.Config
  doctest Config

  test "#new should ensure sid is uppercase" do
    conf = %{sid: "foo", identity: "ping"}

    assert %Config{sid: "FOO"} = Config.new(conf)
  end

  test "#new should ensure identity is uppercase" do
     conf = %{sid: "foo", identity: "ping"}

    assert %Config{identity: "PING"} = Config.new(conf)
  end

  test "#new should default timeout to 1000" do
     conf = %{sid: "foo", identity: "ping"}

    assert %Config{timeout: 1000} = Config.new(conf)
  end

  test "#new should allow custom timeout" do
    conf = %{sid: "foo", identity: "ping", timeout: 1500}

    assert %Config{timeout: 1500} = Config.new(conf)
  end

  test "#new should default broker to tcp://127.0.0.1:7777" do
    conf = %{sid: "foo", identity: "ping"}

    assert %Config{broker: "tcp://127.0.0.1:7777"} = Config.new(conf)
  end

  test "#new should allow custom value for broker" do
    conf = %{sid: "foo", identity: "ping", broker: "tcp://127.0.0.2:7777"}

    assert %Config{broker: "tcp://127.0.0.2:7777"} = Config.new(conf)
  end
end
