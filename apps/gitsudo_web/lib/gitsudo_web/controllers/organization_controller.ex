defmodule GitsudoWeb.OrganizationController do
  use GitsudoWeb, :controller

  require Logger

  import GitsudoWeb.OrgScope

  plug :fetch_org

  @spec show(Plug.Conn.t(), any) :: Plug.Conn.t()
  def show(conn, params) do
    render(conn, :show)
  end
end
