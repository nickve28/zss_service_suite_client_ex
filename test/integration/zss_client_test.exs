defmodule ZssClientTest do
  use ExUnit.Case
  doctest ZssClient

  alias ZssClient.Config

  describe "#get_config" do
    test "should create a config" do
      assert %Config{identity: "FOO"} = ZssClient.get_config(%{identity: "FOO", sid: "PING"})
    end
  end
end
