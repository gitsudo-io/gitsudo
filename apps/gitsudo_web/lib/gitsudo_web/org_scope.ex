defmodule GitsudoWeb.OrgScope do
  @moduledoc """
  A plug for anything under /{org}/
  """
  use GitsudoWeb, :verified_routes

  import Plug.Conn

  require Logger

  @spec fetch_org(Plug.Conn.t(), any) :: Plug.Conn.t()
  @doc """
  Fetch the /{org}, or 404
  """
  def fetch_org(conn, _opts) do
    if organization_name = conn.params["organization_name"] do
      if organization = Gitsudo.Organizations.get_organization(organization_name) do
        conn |> assign(:organization, organization)
      else
        conn |> send_resp(:not_found, "Not found") |> halt
      end
    else
      conn
    end
  end
end
