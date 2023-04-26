defmodule GitsudoWeb.API.RepoScope do
  @moduledoc """
  A plug for /api/org/{org}/{repo}/* routes that attempts to fetch the Gitsudo.Repositories.Repository
  and assign it to `:repository` in the connection.
  """
  use GitsudoWeb, :verified_routes

  import Plug.Conn

  require Logger

  @spec fetch_repo(Plug.Conn.t(), any) :: Plug.Conn.t()
  @doc """
  Fetch the {repo}, or 404
  """
  def fetch_repo(%{assigns: %{organization: organization}} = conn, _opts) do
    if repo_name = conn.params["repo_name"] do
      if repository =
           Gitsudo.Repositories.get_repository_by_owner_id_and_name(organization.id, repo_name,
             preload: [:owner, labels: [:collaborator_policies]]
           ) do
        conn |> assign(:repository, repository)
      else
        conn |> send_resp(:not_found, "Not found") |> halt
      end
    else
      conn
    end
  end

  def fetch_repo(conn, _opts) do
    Logger.debug(conn.assigns |> Map.keys() |> inspect())
    conn |> send_resp(:not_found, "Not found") |> halt
  end
end
