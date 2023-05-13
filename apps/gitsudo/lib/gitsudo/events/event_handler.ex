defmodule Gitsudo.Events.EventHandler do
  @moduledoc """
  Defines an event handler protocol.
  """

  @callback handle(access_token :: String.t(), data :: any()) :: {:ok, any()} | {:error, any()}
end
