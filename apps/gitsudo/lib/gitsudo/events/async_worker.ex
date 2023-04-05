defmodule Gitsudo.Events.AsyncWorker do
  @moduledoc """
  The AsyncWorker GenServer is responsible for handling asynchronous events.
  """

  use GenServer

  require Logger

  @spec start_link(any) :: {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  @impl true
  @spec init(any) :: {:ok, any}
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_cast({event_name, data}, state) do
    Logger.debug("handle_cast({:#{event_name}, #{inspect(data)}}, state)")
    apply(__MODULE__, :"handle_#{event_name}", [data])

    {:noreply, state}
  end

  @doc """
  Actually handle the app_installation_created event.
  """
  @spec handle_app_installation_created(any) :: any
  def handle_app_installation_created(%{"installation" => installation}) do
    Logger.debug("handle_app_installation_created(#{inspect(installation)})")
    Gitsudo.GitHub.create_app_installation(installation)
  end
end
