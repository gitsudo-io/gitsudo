defmodule Gitsudo.Events do
  @moduledoc """
  The Events context provides the interface for calling asynchronous event handlers.

  It delegates all its work to the Gitsudo.Events.AsyncWorker GenServer.
  """

  alias Gitsudo.Events.AsyncWorker

  @doc """
  Dispatch the `app_installation_created` event.
  """
  @spec app_installation_created(data :: map()) :: :ok
  def app_installation_created(%{"action" => "created", "installation" => _} = data) do
    GenServer.cast(AsyncWorker, {:app_installation_created, data})
  end

  @doc """
  Dispatch the `workflow_run_in_progress` event.
  """
  @spec workflow_run_in_progress(data :: map()) :: :ok
  def workflow_run_in_progress(%{"action" => "in_progress", "workflow_run" => _} = data) do
    GenServer.cast(AsyncWorker, {:workflow_run_in_progress, data})
  end

  @doc """
  Dispatch the `workflow_run_completed` event.
  """
  @spec workflow_run_completed(data :: map()) :: :ok
  def workflow_run_completed(%{"action" => "completed", "workflow_run" => _} = data) do
    GenServer.cast(AsyncWorker, {:workflow_run_completed, data})
  end

  @doc """
  Dispatch the `workflow_job_completed` event.
  """
  @spec workflow_job_completed(data :: map()) :: :ok
  def workflow_job_completed(%{"action" => "completed", "workflow_job" => _} = data) do
    GenServer.cast(AsyncWorker, {:workflow_job_completed, data})
  end

  @spec repository_labels_changed(
          repository :: %Gitsudo.Repositories.Repository{},
          changes :: map()
        ) :: :ok
  def repository_labels_changed(repository, changes) do
    GenServer.cast(AsyncWorker, {Gitsudo.Events.RepositoryLabelsChanged, {repository, changes}})
  end

  @spec label_changed(
          label_before :: %Gitsudo.Labels.Label{},
          label_after :: %Gitsudo.Labels.Label{}
        ) :: :ok
  def label_changed(label_before, label_after) do
    GenServer.cast(AsyncWorker, {Gitsudo.Events.LabelChanged, {label_before, label_after}})
  end
end
