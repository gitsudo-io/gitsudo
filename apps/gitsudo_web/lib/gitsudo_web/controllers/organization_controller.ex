defmodule GitsudoWeb.OrganizationController do
  use GitsudoWeb, :controller

  require Logger

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, params) do
    Logger.debug("org: #{params["org"]}")

    conn |> fetch_organization(params["org"]) |> render(:index)
  end

  @spec fetch_organization(conn :: Plug.Conn.t(), organization :: String.t()) :: Plug.Conn.t()
  def fetch_organization(conn, organization) when is_binary(organization) do
    conn |> assign(:organization, %{"login" => organization})
  end
end
