defmodule ZssClient.Adapters.Sender do
  @moduledoc """
  Behavior for data sending, used for contract
  """

  @callback new_socket(%{type: atom(), identity: String.t}) :: pid()
  @callback connect(pid(), String.t, String.t) :: :ok
  @callback send(pid(), ZssService.Message) :: :ok
  @callback get_response(atom()) :: [any()]
  @callback cleanup(pid(), pid()) :: :ok
end
