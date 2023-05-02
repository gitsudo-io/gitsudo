defmodule GitsudoWeb.API.LabelController do
  use GitsudoWeb, :controller

  alias Gitsudo.Labels
  alias Gitsudo.Labels.Label

  require Logger

  action_fallback GitsudoWeb.FallbackController

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(%{assigns: %{organization: organization}} = conn, params) do
    labels = Labels.list_organization_labels(organization.id) |> filter_labels(params)

    conn
    |> render(:index, labels: labels)
  end

  defp filter_labels(labels, %{"s" => s}) do
    Enum.filter(labels, fn label ->
      label.name |> String.downcase() |> String.contains?(String.downcase(s))
    end)
  end

  defp filter_labels(labels, _), do: labels

  @spec create(
          %{
            :assigns => %{
              :organization => %{:id => integer, optional(any) => any},
              optional(any) => any
            },
            optional(any) => any
          },
          map
        ) :: Plug.Conn.t()
  def create(%{assigns: %{organization: organization}} = conn, %{"label" => label_params}) do
    with {:ok, %Label{} = label} <- Labels.create_label(organization.id, label_params) do
      Logger.debug("label => #{inspect(label)}")

      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/org/#{organization.login}/labels/#{label}")
      |> render(:show, label: label)
    end
  end

  @spec show(
          %{
            :assigns => %{
              :organization => %{:id => integer, optional(any) => any},
              optional(any) => any
            },
            optional(any) => any
          },
          map
        ) :: Plug.Conn.t()
  def show(%{assigns: %{organization: organization}} = conn, %{"id" => id}) do
    label = Labels.get_label!(organization.id, id)
    render(conn, :show, label: label)
  end

  @spec update(
          %{
            :assigns => %{
              :organization => %{:id => integer, optional(any) => any},
              optional(any) => any
            },
            optional(any) => any
          },
          map
        ) :: any
  def update(%{assigns: %{organization: organization}} = conn, %{
        "id" => id,
        "label" => label_params
      }) do
    Logger.debug("label_params => #{inspect(label_params)}")
    label = Labels.get_label!(organization.id, id)

    with {:ok, %Label{} = label} <- Labels.update_label(label, label_params) do
      render(conn, :show, label: label)
    end
  end

  def delete(%{assigns: %{organization: organization}} = conn, %{
        "id" => id
      }) do
    label = Labels.get_label!(organization.id, id)

    with {:ok, %Label{}} <- Labels.delete_label(label) do
      send_resp(conn, :no_content, "")
    end
  end
end
