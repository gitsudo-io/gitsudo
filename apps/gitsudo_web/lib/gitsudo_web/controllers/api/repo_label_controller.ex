defmodule GitsudoWeb.API.RepoLabelController do
  @moduledoc """
  /api/org/{org}/{repo}/labels
  """

  use GitsudoWeb, :controller

  alias Gitsudo.Labels
  alias Gitsudo.Labels.Label

  require Logger

  action_fallback GitsudoWeb.FallbackController

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(%{assigns: %{organization: organization, repository: repository}} = conn, params) do
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
end
