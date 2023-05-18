defmodule Gitsudo.Events.LabelChanged do
  @moduledoc """
  The handler or actual worker code for the LabelChanged event,
  Called by Gitsudo.Events.AsyncWorker.
  """

  alias Gitsudo.Repo

  require Logger

  @behaviour Gitsudo.Events.EventHandler

  def handle(
        access_token,
        {
          %Gitsudo.Labels.Label{} = label_before,
          %Gitsudo.Labels.Label{} = label_after
        }
      ) do
    label_before =
      Repo.preload(label_before, repositories: [:owner], collaborator_policies: [:collaborator])

    Logger.debug("access_token => #{inspect(access_token)}")
    Logger.debug("label_before => #{inspect(label_before)}")
    Logger.debug("label_after => #{inspect(label_after)}")

    Logger.debug(
      "repositories_to_apply_to => #{inspect(label_before.repositories |> Enum.map(& &1.name))}"
    )

    if !Enum.empty?(label_before.repositories) do
      apply_team_permissions(access_token, label_before, label_after)
      apply_collaborators(access_token, label_before, label_after)
    end

    {:ok, label_after}
  end

  def apply_team_permissions(access_token, label_before, label_after) do
    team_policies_before =
      label_before.team_policies
      |> MapUtils.from_enum(& &1.team_slug, &to_string(&1.permission))

    team_policies_after =
      label_after.team_policies |> MapUtils.from_enum(& &1.team_slug, &to_string(&1.permission))

    {team_policies_to_remove_only, team_policies_to_update, team_policies_to_add_only} =
      MapUtils.delta(team_policies_before, team_policies_after)

    Logger.debug("team_policies_to_remove_only => #{inspect(team_policies_to_remove_only)}")
    Logger.debug("team_policies_to_update => #{inspect(team_policies_to_update)}")
    Logger.debug("team_policies_to_add_only => #{inspect(team_policies_to_add_only)}")

    Enum.each(label_before.repositories, fn repository ->
      repository = Repo.preload(repository, [:owner])

      GitHub.Repositories.apply_repository_team_permission_changes(
        access_token,
        repository.owner.login,
        repository.name,
        team_policies_to_remove_only,
        team_policies_to_update,
        team_policies_to_add_only
      )
    end)
  end

  defp apply_collaborators(access_token, label_before, label_after) do
    collaborators_before =
      label_before.collaborator_policies
      |> MapUtils.from_enum(& &1.collaborator.login, &to_string(&1.permission))

    collaborators_after =
      label_after.collaborator_policies
      |> MapUtils.from_enum(& &1.collaborator.login, &to_string(&1.permission))

    {collaborators_to_remove_only, collaborators_to_update, collaborators_to_add_only} =
      MapUtils.delta(collaborators_before, collaborators_after)

    Logger.debug("collaborators_to_remove_only => #{inspect(collaborators_to_remove_only)}")
    Logger.debug("collaborators_to_update => #{inspect(collaborators_to_update)}")
    Logger.debug("collaborators_to_add_only => #{inspect(collaborators_to_add_only)}")

    Enum.each(label_before.repositories, fn repository ->
      repository = Repo.preload(repository, [:owner])

      GitHub.Repositories.apply_repository_collaborator_permission_changes(
        access_token,
        repository.owner.login,
        repository.name,
        collaborators_to_remove_only,
        collaborators_to_update,
        collaborators_to_add_only
      )
    end)
  end
end
