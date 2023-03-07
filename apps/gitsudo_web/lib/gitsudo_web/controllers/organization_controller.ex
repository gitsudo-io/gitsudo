defmodule GitsudoWeb.OrganizationController do
  use GitsudoWeb, :controller

  require Logger

  @spec show(Plug.Conn.t(), any) :: Plug.Conn.t()
  def show(conn, params) do
    Logger.debug("org: #{params["name"]}")

    conn |> fetch_organization(params["name"])
  end

  @spec fetch_organization(conn :: Plug.Conn.t(), name :: String.t()) :: Plug.Conn.t()
  def fetch_organization(conn, name) when is_binary(name) do
    if organization = Gitsudo.Organizations.get_organization(name) do
      conn |> assign(:organization, organization) |> render(:show)
    else
      conn |> send_resp(:not_found, "Not found") |> halt
    end
  end
end
