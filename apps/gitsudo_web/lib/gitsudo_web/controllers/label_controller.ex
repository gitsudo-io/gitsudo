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
    assign(
      conn,
      :labels,
      Labels.list_organization_labels(organization.id, preload: [:repositories])
    )
  end

  def new(conn, _params) do
    changeset = Labels.change_label(%Label{})
    render(conn, :new, changeset: changeset)
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(%{assigns: %{organization: organization}} = conn, %{"label" => label_params}) do
    params = Map.put(label_params, "owner_id", organization.id)

    case Labels.create_label(organization.id, params) do
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

  def show(%{assigns: %{organization: organization}} = conn, %{
        "name" => name
      }) do
    if label = Labels.get_label_by_name(organization.id, name) do
      render(conn, :show, label: label)
    else
      conn |> send_resp(:not_found, "Not found") |> halt
    end
  end

  def edit(%{assigns: %{organization: organization}} = conn, %{
        "name" => name
      }) do
    if label = Labels.get_label_by_name(organization.id, name) do
      changeset = Labels.change_label(label)

      render(conn, :edit, label: label, changeset: changeset)
    else
      conn |> send_resp(:not_found, "Not found") |> halt
    end
  end

  @doc """
  POST /:owner/:repo/labels
  """
  def update(
        %{assigns: %{organization: organization}} = conn,
        %{
          "name" => name,
          "label" => label_params
        } = params
      ) do
    if label = Labels.get_label_by_name(organization.id, name) do
      team_policies = build_team_policies(params)
      Logger.debug("team_policies => #{inspect(team_policies)}}")
      collaborator_policies = build_collaborator_policies(label, params)
      Logger.debug("collaborator_policies => #{inspect(collaborator_policies)}")

      attrs =
        Map.put(label_params, "team_policies", team_policies)
        |> Map.put("collaborator_policies", collaborator_policies)

      with {:ok, %Label{} = label} <- Labels.update_label(label, attrs) do
        redirect(conn, to: ~p"/#{organization.login}/labels/#{label.name}")
      end
    else
      conn |> send_resp(:not_found, "Not found") |> halt
    end
  end

  defp build_team_policies(params) do
    Logger.debug("params => #{inspect(params)}")
    extract_existing_team_permissions(params)
  end

  defp extract_existing_team_permissions(%{
         "team_permissions_ids" => team_permission_ids,
         "team_permissions_teams" => team_permissions_teams,
         "team_permissions_permissions" => team_permissions_permissions
       }) do
    Enum.zip([
      team_permission_ids,
      team_permissions_teams,
      team_permissions_permissions
    ])
    |> Enum.map(fn {id, team_slug, permission} ->
      %{
        id: id,
        team_slug: team_slug,
        permission: permission
      }
    end)
  end

  defp extract_existing_team_permissions(_label_params), do: []

  defp build_collaborator_policies(label, params) do
    label.collaborator_policies
    |> collaborator_policies_as_params()
    |> remove_collaborator_policies_for_deletion(params)
  end

  defp collaborator_policies_as_params(collaborator_policies) do
    Enum.map(collaborator_policies, fn cp ->
      %{
        id: cp.id,
        collaborator_id: cp.collaborator_id,
        permission: cp.permission
      }
    end)
  end

  defp remove_collaborator_policies_for_deletion(
         collaborator_policies,
         %{"collaborator_policy_ids_for_deletion" => collaborator_policy_ids_for_deletion} =
           _params
       ) do
    Logger.debug("Removing #{inspect(collaborator_policy_ids_for_deletion)}...")

    collaborator_policy_ids_for_deletion
    |> Enum.reduce(collaborator_policies, fn id, cps ->
      Enum.reject(cps, &(&1.id == String.to_integer(id)))
    end)
  end

  defp remove_collaborator_policies_for_deletion(collaborator_policies, _),
    do: collaborator_policies

  def delete(%{assigns: %{organization: organization}} = conn, %{
        "name" => name
      }) do
    label = Labels.get_label!(organization.id, name)

    with {:ok, %Label{}} <- Labels.delete_label(label) do
      send_resp(conn, :no_content, "")
    end
  end
end
