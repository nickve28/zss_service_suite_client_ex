defmodule ZssClient.Address do
  @moduledoc """
  A struct containing all logic on how the ZSS Address Frame should be constructed.
  """

  defstruct [
    sid: nil,
    sversion: nil,
    verb: nil
  ]

  @doc """
  Constructs a ZSS Address Frame.

  ## Examples

  iex> ZssClient.Address.new(%{"sid" => "a", "verb" => "b", "sversion" => "c"})
  %ZssClient.Address{sid: "a", verb: "b", sversion: "c"}

  iex> ZssClient.Address.new(%{sid: "a", verb: "b", sversion: "c"})
  %ZssClient.Address{sid: "a", verb: "b", sversion: "c"}
  """
  def new(%{"sid" => sid, "verb" => verb, "sversion" => sversion}) do
    %ZssClient.Address{
      sid: sid, verb: verb, sversion: sversion
    }
  end

  def new(%{sid: sid, verb: verb, sversion: sversion}) do
    %ZssClient.Address{
      sid: sid, verb: verb, sversion: sversion
    }
  end
end

defmodule ZssClient.Message do
  @moduledoc """
  A struct containing all logic on how the ZSS Frames should be constructed.
  """

  alias ZssClient.Address

  import Msgpax

  defstruct [
    identity: nil,
    protocol: "ZSS:0.0",
    type: "REQ",
    rid: nil,
    address: %ZssClient.Address{},
    headers: nil,
    status: "",
    payload: nil
  ]

  @doc """
  Creates a new ZssClient.Message, with the specified sid, verb and sversion (or default = *)
  Please use this to ensure proper message construction.

  Args:

  - sid: The service identity to route to\n
  - verb: The verb to which should be called\n
  - sversion: The version to use. Default to *

  ## Examples

  iex> %ZssClient.Message{address: %{verb: verb, sid: sid, sversion: sversion}, rid: rid} = ZssClient.Message.new("API:1", "GET")
  iex> {verb, sid, sversion, is_binary(rid)}
  {"GET", "API:1", "*", true}
  """
  def new(sid, verb, sversion \\ "*") do
    %ZssClient.Message{
      address: Address.new(%{
        sid: sid,
        sversion: sversion,
        verb: verb
      }),
      rid: UUID.uuid1()
    }
  end

  @doc """
  Serializes a message to Frames, intended to be sent over via ZeroMQ

  Args:

  - message: A ZssClient.Message

  ## Examples

  iex> message = ZssClient.Message.new("SMI", "UP")
  iex> %ZssClient.Message{address: %{verb: "UP", sid: "SMI", sversion: "*"}, rid: rid, type: "REQ", status: ""} = message
  iex> message = %ZssClient.Message{message | identity: "SMI:1", payload: "MYSERVICE:2"}
  iex> frames = ZssClient.Message.to_frames(message)
  iex> ["SMI:1", "ZSS:0.0", "REQ", ^rid, encoded_address, encoded_headers, "", encoded_payload] = frames
  iex> Msgpax.pack!(Map.from_struct(message.address), iodata: false) === encoded_address
  true
  iex> Msgpax.pack!(message.headers, iodata: false) === encoded_headers
  true
  iex> Msgpax.pack!(message.payload, iodata: false) === encoded_payload
  true
  """
  def to_frames(message) do
    [
      message.identity || "",
      message.protocol,
      message.type,
      message.rid,
      pack!(Map.from_struct(message.address), iodata: false),
      pack!(message.headers, iodata: false),
      message.status, #todo, investigate why integer / nil fails
      pack!(message.payload, iodata: false)
    ]
  end

  @doc """
  Parses Frames to a ZssClient.Message. Used to deserialize messages.

  args:

  - frames: Array of frames with or without identity. (7 or 8 length)

  ## Examples:

  iex> encoded_address = %{sid: "API:1", verb: "GET", sversion: "*"} |> Msgpax.pack!
  iex> encoded_headers = %{headers: %{"X-REQUEST-ID" => "123"}} |> Msgpax.pack!
  iex> encoded_payload = %{id: "1"} |> Msgpax.pack!
  iex> rid = "5698bd54-3cbb-11e7-b6df-f40f2419fa47"
  iex> frames = ["ZSS:0.0", "REP", rid, encoded_address, encoded_headers, "200", encoded_payload]
  iex> message = ZssClient.Message.parse(frames)
  iex> %ZssClient.Message{rid: ^rid, status: "200", type: "REP", protocol: "ZSS:0.0"} = message
  iex> %ZssClient.Message{headers: headers, payload: payload, address: _address} = message
  iex> headers
  %{"headers" => %{"X-REQUEST-ID" => "123"}}
  iex> payload
  %{"id" => "1"}
  """
  def parse([protocol, type, rid, encoded_address, encoded_headers, status, encoded_payload]) do
    parse(["", protocol, type, rid, encoded_address, encoded_headers, status, encoded_payload])
  end

  def parse([identity, protocol, type, rid, encoded_address, encoded_headers, status, encoded_payload]) do
    %ZssClient.Message{
      identity: identity,
      protocol: protocol,
      type: type,
      rid: rid,
      address: Address.new(unpack!(encoded_address)),
      headers: unpack!(encoded_headers),
      status: status,
      payload: unpack!(encoded_payload)
    }
  end
end
