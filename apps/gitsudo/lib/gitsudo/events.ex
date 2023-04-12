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

  @doc """
  Dispatch the `workflow_job_completed` event.
  """
  @spec workflow_job_completed(any) :: :ok
  def workflow_job_completed(data) do
    GenServer.cast(AsyncWorker, {:workflow_job_completed, data})
  end
end
