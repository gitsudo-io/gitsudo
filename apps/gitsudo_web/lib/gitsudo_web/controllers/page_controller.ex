defmodule GitsudoWeb.PageController do
  use GitsudoWeb, :controller

  alias Gitsudo.Accounts

  require Logger

  @spec home(Plug.Conn.t(), any) :: Plug.Conn.t()
  def home(conn, _params) do
    conn |> list_repositories |> render(:home)
  end

  @spec list_repositories(Plug.Conn.t()) :: Plug.Conn.t()
  def list_repositories(conn) do
    with user <- conn.assigns[:current_user],
         user_session <- Accounts.get_user_session(user.id) do
      case Gitsudo.Repositories.list_user_repositories(user, user_session.access_token) do
        {:ok, repositories} ->
          Logger.debug("list_user_repositories() found: #{length(repositories)}")
          conn |> assign(:repositories, repositories)

        {:error, "401 Unauthorized"} ->
          Logger.error("list_user_repositories() returned: 401 Unauthorized")

          conn
          |> put_flash(:error, "You must log in to access this page.")
          |> maybe_store_return_to()
          |> redirect(to: ~p"/login")
          |> halt()

        {:error, reason} ->
          Logger.error("list_user_repositories() returned: #{reason}")
          conn
      end
    else
      _ ->
        conn
    end
  end

  @spec login(Plug.Conn.t(), any) :: Plug.Conn.t()
  def login(conn, _params) do
    client_id = Application.fetch_env!(:gitsudo_web, GitsudoWeb.Endpoint)[:github_client_id]
    render(conn, :login, client_id: client_id)
  end

  @spec logout(Plug.Conn.t(), any) :: Plug.Conn.t()
  def logout(conn, _params) do
    conn
    |> delete_session(:user_id)
    |> redirect(to: ~p"/")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn
end
