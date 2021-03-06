defmodule Example.Ping do
  @moduledoc false

  alias ZssClient.{Client}

  def start do
    {:ok, client} = %{sid: "PING_ME", identity: "EXAMPLE_CLIENT"}
    |> ZssClient.get_config
    |> ZssClient.get_client

    options = %{
      headers: %{
        "X-REQUEST-ID" => "123"
      }
    }

    :ok = Client.call(client, {"list", %{id: "1"}, options})
    {:ok, _payload, _headers} = Client.get_response(client)
  end
end

Example.Ping.start
