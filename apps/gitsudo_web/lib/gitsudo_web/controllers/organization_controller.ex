defmodule GitsudoWeb.OrganizationController do
  use GitsudoWeb, :controller

  require Logger

  @spec show(Plug.Conn.t(), any) :: Plug.Conn.t()
  def show(conn, params) do
    Logger.debug("org: #{params["name"]}")

    conn |> fetch_organization(params["name"]) |> render(:show)
  end

  @spec fetch_organization(conn :: Plug.Conn.t(), organization :: String.t()) :: Plug.Conn.t()
  def fetch_organization(conn, organization) when is_binary(organization) do
    conn |> assign(:organization, %{"login" => organization})
  end
end
