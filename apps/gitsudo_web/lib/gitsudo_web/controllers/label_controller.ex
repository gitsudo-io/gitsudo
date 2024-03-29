defmodule GitsudoWeb.LabelController do
  use GitsudoWeb, :controller

  alias Gitsudo.Accounts
  alias Gitsudo.Organizations
  alias Gitsudo.Labels
  alias Gitsudo.Labels.Label

  require Logger

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(%{assigns: %{organization: organization}} = conn, _params) do
    conn
    |> fetch_labels()
    |> assign(:page_title, "#{organization.login} - Labels")
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
      conn
      |> assign(:page_title, "#{organization.login} - #{label.name}")
      |> render(:show, label: label)
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
        %{assigns: %{organization: organization, user_role: user_role}} = conn,
        %{
          "name" => name,
          "label" => label_params
        } = params
      ) do
    if label = Labels.get_label_by_name(organization.id, name) do
      if user_role == "admin" do
        team_policies = build_team_policies(params)
        Logger.debug("team_policies => #{inspect(team_policies)}}")
        collaborator_policies = build_collaborator_policies(organization, params)
        Logger.debug("collaborator_policies => #{inspect(collaborator_policies)}")

        attrs =
          Map.put(label_params, "team_policies", team_policies)
          |> Map.put("collaborator_policies", collaborator_policies)

        with {:ok, %Label{} = label} <- Labels.update_label(label, attrs) do
          redirect(conn, to: ~p"/#{organization.login}/labels/#{label.name}")
        end
      else
        conn
        |> send_resp(:unauthorized, "Unauthorized")
        |> halt()
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

  defp build_collaborator_policies(organization, params) do
    extract_collorator_policies(params)
    |> add_new_collaborators(organization, params)
  end

  defp extract_collorator_policies(
         %{
           "collaborator_policy_ids" => collaborator_policy_ids,
           "collaborator_policy_collaborator_ids" => collaborator_policy_collaborator_ids,
           "collaborator_policy_permissions" => collaborator_policy_permissions
         } = _params
       ) do
    Enum.zip([
      collaborator_policy_ids,
      collaborator_policy_collaborator_ids,
      collaborator_policy_permissions
    ])
    |> Enum.map(fn {id, collaborator_id, permission} ->
      %{
        id: id,
        collaborator_id: collaborator_id,
        permission: permission
      }
    end)
  end

  defp extract_collorator_policies(_params), do: []

  defp add_new_collaborators(
         collaborator_policies,
         organization,
         %{
           "new_collaborator_logins" => new_collaborator_logins,
           "new_collaborator_permissions" => new_collaborator_permissions
         } = _params
       ) do
    Enum.zip([new_collaborator_logins, new_collaborator_permissions])
    |> Enum.reduce(collaborator_policies, fn {login, permission}, collaborator_policies ->
      case Accounts.find_or_fetch_account(organization, login) do
        {:ok, account} ->
          Logger.debug("Adding #{login} with permission #{permission}...")

          [
            %{
              id: nil,
              collaborator_id: account.id,
              permission: permission
            }
            | collaborator_policies
          ]

        _ ->
          Logger.error("Could not find Account with login \"#{login}\"!")
          collaborator_policies
      end
    end)
  end

  defp add_new_collaborators(collaborator_policies, _, _), do: collaborator_policies

  def delete(%{assigns: %{organization: organization}} = conn, %{
        "name" => name
      }) do
    label = Labels.get_label!(organization.id, name)

    with {:ok, %Label{}} <- Labels.delete_label(label) do
      send_resp(conn, :no_content, "")
    end
  end
end
