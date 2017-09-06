# ZSS ZeroMQ Service Client

[![Build Status](https://travis-ci.org/nickve28/zss_service_suite_client_ex.svg?branch=master)](https://travis-ci.org/nickve28/zss_service_suite_client_ex)

**Warning: NOT PRODUCTION READY**

## Purpose

This is an Elixir implementation of a client for the [Micro Toolkit ZSS Broker](https://github.com/micro-toolkit/zmq-service-suite-broker-js). This is not an official repo.

It allows connecting your Elixir application to an existing NodeJS project using the Broker and its associated clients/workers.

## When to use this

This library is intended to use when you need/want to introduce Elixir to your existing stack, which uses the ZSS Suite.

## Installation

T.B.D.

## Creating a Client and calling a Service Worker

In order to create a client, you start by creating an appropriate configuration.
Note that broker and timeout are optional, and will default to the shown values respectively.

```elixir
config = ZssClient.get_instance %{identity: "EXAMPLE_CLIENT", broker: "tcp://127.0.0.1:7777", timeout: 1000, sid: "PING"}
```

Based on the config, you can instantiate Clients.

```elixir
{:ok, client} = ZssClient.get_client(config)
```

This client can be used to make calls to various specified endpoints.

```elixir
ZssClient.call(client, request)
with {:ok, payload, status} <- ZssClient.get_response(client) do
  IO.inspect("Received #{inspect payload} with status #{inspect status}")
  {:ok, status}
else
  {:error, payload, code} ->
  IO.inspect("Error! #{inspect payload} with status #{inspect status}")
  {:error, status}
end
```

Note that receiving messages (get_response) is a blocking action for that client, but calling a service is not. In case you want to perform multiple actions, you can do something akin to

```elixir
config = ZssClient.get_config %{identity: "EXAMPLE_CLIENT", broker: "tcp://127.0.0.1:7777", timeout: 1000, sid: "PING"}
config2 = ZssClient.get_config %{identity: "EXAMPLE_CLIENT", broker: "tcp://127.0.0.1:7777", timeout: 1000, sid: "PONG"}

{:ok, ping_client} = ZssClient.get_client(config)
{:ok, pong_client} = ZssClient.get_client(config2)

with :ok <- ZssClient.call(ping_client, {"GET", %{}, %{headers: %{request_id: "1"}}}),
     :ok <- ZssClient.call(pong_client, {"LIST", %{}, %{headers: %{request_id: "1"}}}),
     [ping_reply, pong_reply] <- [ZssClient.get_response(ping_client), ZssClient.get_response(pong_client)],
do
  #handle 2 messages
else
  error -> #handle error
end
```
## Client Response contract

Clients will return a 3 value tuple, with the following properties:


| Property | Type | Description |
|--------|------------|-------------|
| indicator | atom    | Indicates whether the request can be considered succesfull or an error. Signalled by :ok or :error respectively.
| payload | Mixed     | The response payload. Keep in mind that data is deserialized and atom based maps get converted to string key maps.
| code    | Integer   | The status code associated with the request. Maps to HTTP codes.

## Supervising

This library has a supervisor that each running client will reside under. Currently processes will not be rebooted if they crash.

## Running the example

Just execute

```
mix run ./examples/ping.exs
```

