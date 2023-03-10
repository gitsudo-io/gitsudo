defmodule GitsudoWeb.API.LabelController do
  use GitsudoWeb, :controller

  alias Gitsudo.Labels
  alias Gitsudo.Labels.Label

  action_fallback GitsudoWeb.FallbackController

  def index(%{assigns: %{organization: organization}} = conn, _params) do
    labels = Labels.list_organization_labels(organization.id)
    render(conn, :index, labels: labels)
  end

  def create(conn, %{"label" => label_params}) do
    with {:ok, %Label{} = label} <- Labels.create_label(label_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/labels/#{label}")
      |> render(:show, label: label)
    end
  end

  def show(conn, %{"id" => id}) do
    label = Labels.get_label!(id)
    render(conn, :show, label: label)
  end

  def update(conn, %{"id" => id, "label" => label_params}) do
    label = Labels.get_label!(id)

    with {:ok, %Label{} = label} <- Labels.update_label(label, label_params) do
      render(conn, :show, label: label)
    end
  end

  def delete(conn, %{"id" => id}) do
    label = Labels.get_label!(id)

    with {:ok, %Label{}} <- Labels.delete_label(label) do
      send_resp(conn, :no_content, "")
    end
  end
end
