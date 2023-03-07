defmodule GitsudoWeb.LabelController do
  use GitsudoWeb, :controller

  alias Gitsudo.Labels
  alias Gitsudo.Labels.Label

  require Logger

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    conn
    |> fetch_labels()
    |> render(:index)
  end

  def fetch_labels(%{assigns: %{organization: organization}} = conn) do
    assign(conn, :labels, Labels.list_organization_labels(organization.id))
  end

  def new(conn, _params) do
    changeset = Labels.change_label(%Label{})
    render(conn, :new, changeset: changeset)
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(%{assigns: %{organization: organization}} = conn, %{"label" => label_params}) do
    params = Map.put(label_params, "owner_id", organization.id)

    case Labels.create_label(params) do
      {:ok, %Label{} = _label} ->
        conn
        |> put_flash(:info, "Label created successfully.")
        |> fetch_labels()
        |> redirect(to: ~p"/#{organization.login}/labels")

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error(inspect(changeset))
        render(conn, :new, changeset: changeset)
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
