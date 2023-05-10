defmodule GitsudoWeb.API.RepoLabelController do
  @moduledoc """
  /api/org/{org}/{repo}/labels
  """

  use GitsudoWeb, :controller

  alias Gitsudo.Repositories

  require Logger

  action_fallback GitsudoWeb.FallbackController

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(%{assigns: %{organization: _organization, repository: repository}} = conn, _params) do
    repository =
      repository
      |> Gitsudo.Repo.preload([
        :owner,
        labels: [:team_policies, collaborator_policies: [:collaborator]]
      ])

    for label <- repository.labels do
      Logger.debug("label => #{inspect(label)}")
      Logger.debug("label.collaborator_policies => #{inspect(label.collaborator_policies)}")
    end

    conn
    |> put_view(json: GitsudoWeb.API.LabelJSON)
    |> render(:index, labels: repository.labels)
  end

  def create(%{assigns: %{organization: _organization, repository: repository}} = conn, params) do
    Logger.debug("params => #{inspect(params)}")

    with {:ok, repository} <-
           repository
           |> Gitsudo.Repo.preload([
             :owner,
             labels: [:team_policies, collaborator_policies: [:collaborator]]
           ])
           |> apply_changes(params["changes"]) do
      conn
      |> put_view(json: GitsudoWeb.API.LabelJSON)
      |> render(:index, labels: repository.labels)
    end
  end

  defp apply_changes(
         repository,
         %{"labelsToRemove" => labels_to_remove, "labelsToAdd" => labels_to_add} = changes
       ) do
    Logger.debug("labelsToRemove => #{inspect(labels_to_remove)}")
    Logger.debug("labelsToAdd => #{inspect(labels_to_add)}")
    repository = Repositories.change_labels(repository, changes)
  end

  defp apply_changes(repository, _), do: {:ok, repository}
end
