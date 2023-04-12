defmodule Gitsudo.Workflows do
  @moduledoc """
  The Workflows context.
  """
  import Ecto.Query, warn: false

  alias Gitsudo.Workflows.Workflow
  alias Gitsudo.Workflows.WorkflowRun
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

  @spec list_workflow_runs(binary, any, any) ::
          {:error,
           nonempty_binary | %{:__exception__ => true, :__struct__ => atom, optional(atom) => any}}
          | {:ok, any}
  def list_workflow_runs(access_token, organization, repository) do
    case GitHub.Client.list_workflow_runs(access_token, organization, repository) do
      {:ok, data} ->
        Logger.debug(
          ~s'Found #{data["total_count"]} workflow runs for "#{organization}/#{repository}"'
        )

        {:ok, data["workflow_runs"]}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
