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
        conn
        |> assign(:organization, organization)
        |> maybe_assign_user_role(organization)
      else
        conn |> send_resp(:not_found, "Not found") |> halt
      end
    else
      conn
    end
  end

  # For testing only, skip GitHub API call if user_role is already assigned.
  # TODO: Find a better way to do this.
  defp maybe_assign_user_role(%{assigns: %{user_role: user_role}} = conn, _organization) do
    Logger.warning("Found existing user_role \"#{user_role}\", skipping GitHub API call")
    conn
  end

  defp maybe_assign_user_role(
         %{assigns: %{user_session: user_session}} = conn,
         organization
       ) do
    case Gitsudo.Organizations.get_user_role(user_session, organization) do
      {:ok, user_role} ->
        Logger.debug("Got user_role: #{user_role}")
        conn |> assign(:user_role, user_role)

      {:error, err} ->
        Logger.error(err)
        conn
    end
  end
end
