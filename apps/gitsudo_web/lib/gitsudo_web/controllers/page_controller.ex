defmodule GitsudoWeb.PageController do
  use GitsudoWeb, :controller

  require Logger

  @spec home(Plug.Conn.t(), any) :: Plug.Conn.t()
  def home(conn, _params) do
    conn |> list_repositories |> render(:home)
  end

  @spec list_repositories(Plug.Conn.t()) :: Plug.Conn.t()
  def list_repositories(conn) do
    with user <- conn.assigns[:current_user],
         access_token <- get_session(conn, :access_token) do
      case Gitsudo.Repositories.list_user_repositories(user, access_token) do
        {:ok, repositories} ->
          Logger.debug("list_user_repositories() found: #{length(repositories)}")
          conn |> assign(:repositories, repositories)

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
    |> delete_session(:access_token)
    |> redirect(to: ~p"/")
  end
end
