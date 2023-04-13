defmodule Gitsudo.Workflows do
  @moduledoc """
  The Workflows context.
  """
  import Ecto.Query, warn: false

  alias Gitsudo.Workflows.Workflow
  alias Gitsudo.Workflows.WorkflowRun
  alias Gitsudo.Workflows.WorkflowJob
  alias Gitsudo.Workflows.WorkflowJobStep
  alias Gitsudo.Repo

  require Logger

  @spec create_workflow(repository_id :: integer, params :: map()) ::
          {:ok, %Workflow{}}
          | {:error, Ecto.Changeset.t()}
  def create_workflow(repository_id, params) do
    %Workflow{
      repository_id: repository_id
    }
    |> Workflow.changeset(params)
    |> Repo.insert()
  end

  @spec create_workflow_run(params :: map()) ::
          {:ok, %WorkflowRun{}}
          | {:error, Ecto.Changeset.t()}
  def create_workflow_run(params) do
    %WorkflowRun{}
    |> WorkflowRun.changeset(params)
    |> Repo.insert()
  end

  @spec insert_or_update_workflow_run(params :: map()) ::
          {:ok, %WorkflowRun{}}
          | {:error, Ecto.Changeset.t()}
  def insert_or_update_workflow_run(params) do
    (Repo.get(WorkflowRun, params["id"]) || %WorkflowRun{})
    |> WorkflowRun.changeset(params)
    |> Repo.insert_or_update()
  end

  @spec create_workflow_job(workflow_run_id :: integer, params :: map()) ::
          {:ok, %WorkflowJob{}}
          | {:error, Ecto.Changeset.t()}
  def create_workflow_job(workflow_run_id, params) do
    %WorkflowJob{
      workflow_run_id: workflow_run_id
    }
    |> WorkflowJob.changeset(params)
    |> Repo.insert()
  end

  @spec create_workflow_job_step(workflow_job_id :: integer, params :: map()) ::
          {:ok, %WorkflowJobStep{}}
          | {:error, Ecto.Changeset.t()}
  def create_workflow_job_step(workflow_job_id, params) do
    elapsed_seconds =
      case {params["started_at"], params["completed_at"]} do
        {nil, _} ->
          nil

        {_, nil} ->
          nil

        {started_at, completed_at} ->
          with {:ok, started_at, 0} <- DateTime.from_iso8601(started_at),
               {:ok, completed_at, 0} <- DateTime.from_iso8601(completed_at) do
            DateTime.diff(completed_at, started_at, :second)
          else
            _ ->
              Logger.error("Failed to parse started_at or completed_at")
              nil
          end
      end

    %WorkflowJobStep{
      workflow_job_id: workflow_job_id,
      elapsed_seconds: elapsed_seconds
    }
    |> WorkflowJobStep.changeset(params)
    |> Repo.insert()
  end

  def list_workflow_runs_for_repository(repository_id) do
    Repo.all(from w in Workflow, where: w.repository_id == ^repository_id)
    |> Enum.reduce([], fn workflow, acc ->
      workflow_runs = Repo.all(from wr in WorkflowRun, where: wr.workflow_id == ^workflow.id)
      acc ++ workflow_runs
    end)
  end
end
