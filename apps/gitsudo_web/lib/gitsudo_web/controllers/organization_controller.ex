defmodule GitsudoWeb.OrganizationController do
  use GitsudoWeb, :controller

  alias Gitsudo.Organizations
  alias Gitsudo.Repositories

  import GitsudoWeb.OrgScope

  require Logger

  plug :fetch_org

  @spec show(Plug.Conn.t(), any) :: Plug.Conn.t()
  def show(conn, %{"organization_name" => organization_name} = _params) do
    if organization = Organizations.get_organization(organization_name) do
      conn
      |> assign(:organization, organization)
      |> fetch_repositories(organization)
      |> render(:show)
    else
      conn |> send_resp(:not_found, "Not found") |> halt
    end
  end

  def fetch_repositories(conn, organization) do
    with _user <- conn.assigns[:current_user],
         access_token <- get_session(conn, :access_token) do
      case Organizations.list_repositories(access_token, organization) do
        {:ok, repositories} ->
          Logger.debug("list_repositories() found: #{length(repositories)}")
          conn |> assign(:repositories, repositories)

        {:error, reason} ->
          Logger.error("list_repositories() returned: #{reason}")
          conn
      end
    end
  end
end
