defmodule GitsudoWeb.OrganizationController do
  use GitsudoWeb, :controller

  alias Gitsudo.Accounts
  alias Gitsudo.Organizations
  alias Gitsudo.Repositories

  import GitsudoWeb.OrgScope

  require Logger

  plug :fetch_org

  @spec show(Plug.Conn.t(), any) :: Plug.Conn.t()
  def show(conn, %{"organization_name" => organization_name} = _params) do
    if organization = Organizations.get_organization(organization_name) do
      labels = Gitsudo.Labels.list_organization_labels(organization.id)

      conn
      |> assign(:page_title, organization.login)
      |> assign(:organization, organization)
      |> assign(:labels, labels)
      |> fetch_repositories(organization)
      |> render(:show)
    else
      conn |> send_resp(:not_found, "Not found") |> halt
    end
  end

  def fetch_repositories(conn, organization) do
    with user <- conn.assigns[:current_user],
         user_session <- Accounts.get_user_session(user.id) do
      case Organizations.list_repositories(user_session.access_token, organization) do
        {:ok, repositories} ->
          Logger.debug("list_repositories() found: #{length(repositories)}")
          conn |> assign(:repositories, repositories)

        {:error, "401 Unauthorized"} ->
          conn
          |> put_flash(:error, "You must log in to access this page.")
          |> maybe_store_return_to()
          |> redirect(to: ~p"/login")
          |> halt()

        {:error, reason} ->
          Logger.error("list_repositories() returned: #{reason}")
          conn
      end
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn
end
