defmodule GitsudoWeb.PageController do
  use GitsudoWeb, :controller

  require Logger

  @spec home(Plug.Conn.t(), any) :: Plug.Conn.t()
  def home(conn, _params) do
    if user = conn.assigns[:current_user] do
      Logger.debug(inspect(user["login"]))
    end

    repositories = []
    render(conn, :home, repositories: repositories)
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
