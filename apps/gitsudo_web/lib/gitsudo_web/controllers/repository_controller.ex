defmodule GitsudoWeb.RepositoryController do
  @moduledoc """
  The repository controller.

  - GET /:organization/:repository
  """
  use GitsudoWeb, :controller

  alias Gitsudo.Repositories

  require Logger

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(%{assigns: %{organization: organization}} = conn, %{
        "name" => name
      }) do
    if repository = Repositories.get_repository_by_owner_id_and_name(organization.id, name) do
      render(conn, :show, repository: repository)
    else
      conn |> send_resp(:not_found, "Not found") |> halt
    end
  end
end
