defmodule GitsudoWeb.RepositoryController do
  use GitsudoWeb, :controller

  alias Gitsudo.Repositories

  require Logger

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
