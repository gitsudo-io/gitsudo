defmodule Gitsudo.Events do
  @moduledoc """
  The Events context provides the interface for calling asynchronous event handlers.

  It delegates all its work to the Gitsudo.Events.AsyncWorker GenServer.
  """

  alias Gitsudo.Events.AsyncWorker

  @doc """
  Dispatch the `app_installation_created` event.
  """
  @spec app_installation_created(any) :: :ok
  def app_installation_created(data) do
    GenServer.cast(AsyncWorker, {:app_installation_created, data})
  end
end
