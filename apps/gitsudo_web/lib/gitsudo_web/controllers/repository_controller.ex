defmodule GitsudoWeb.RepositoryController do
  @moduledoc """
  The repository controller.

  - GET /:organization/:repository
  """
  use GitsudoWeb, :controller

  alias Gitsudo.Repositories
  alias Gitsudo.Workflows

  require Logger

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(%{assigns: %{organization: organization}} = conn, %{
        "name" => name
      }) do
    if repository =
         Repositories.get_repository_by_owner_id_and_name(organization.id, name,
           preload: [
             :owner,
             labels: [:owner, :team_policies, collaborator_policies: [:collaborator]]
           ]
         ) do
      conn
      |> assign(:page_title, "#{organization.login}/#{repository.name}")
      |> assign(:repository, repository)
      |> populate_workflows(repository)
      |> render(:show)
    else
      conn |> send_resp(:not_found, "Not found") |> halt
    end
  end

  @spec populate_workflows(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def populate_workflows(conn, repository) do
    workflow_runs = Workflows.list_workflow_runs_for_repository(repository.id)
    total_count = Enum.count(workflow_runs)

    completed_count =
      Enum.count(workflow_runs, &(&1.status == "completed" && &1.conclusion != "cancelled"))

    success_count = Enum.count(workflow_runs, &(&1.conclusion == "success"))

    success_percentage =
      if completed_count > 0, do: success_count / completed_count * 100, else: 0

    conn
    |> assign(:total_count, total_count)
    |> assign(:completed_count, completed_count)
    |> assign(:success_count, success_count)
    |> assign(:success_percentage, success_percentage)
    |> assign(:workflow_runs, workflow_runs)
  end
end
