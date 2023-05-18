defmodule Gitsudo.Events.RepositoryLabelsChanged do
  @moduledoc """
  The handler or actual worker code for the RepositoryLabelsChanged event.
  Called by Gitsudo.Events.AsyncWorker.
  """

  alias Gitsudo.Repo
  alias Gitsudo.Labels

  require Logger

  @behaviour Gitsudo.Events.EventHandler

  @callback
  def handle(
        access_token,
        {
          %Gitsudo.Repositories.Repository{} = repository,
          %{
            label_ids_to_remove: label_ids_to_remove,
            label_ids_to_add: label_ids_to_add
          } = _changes
        }
      ) do
    Logger.debug("access_token => #{inspect(access_token)}")
    Logger.debug("repository => #{inspect(repository)}")
    Logger.debug("label_ids_to_remove => #{inspect(label_ids_to_remove)}")
    Logger.debug("label_ids_to_add => #{inspect(label_ids_to_add)}")

    label_ids_to_remove = MapSet.new(label_ids_to_remove)
    label_ids_to_add = MapSet.new(label_ids_to_add)

    {labels_to_remove, labels_to_add} =
      fetch_labels(repository.owner_id, label_ids_to_remove, label_ids_to_add)

    apply_team_policy_changes(access_token, repository, labels_to_remove, labels_to_add)

    apply_collaborator_changes(access_token, repository, labels_to_remove, labels_to_add)

    {:ok, repository}

    {:ok, repository}
  end

  defp fetch_labels(owner_id, label_ids_to_remove, label_ids_to_add) do
    labels =
      MapSet.union(label_ids_to_remove, label_ids_to_add)
      |> Enum.uniq()
      |> Enum.reduce(%{}, fn label_id, labels ->
        label =
          Labels.get_label(owner_id, label_id,
            preload: [:team_policies, collaborator_policies: [:collaborator]]
          )

        Map.put(labels, label_id, label)
      end)

    labels_to_remove = Enum.map(label_ids_to_remove, &Map.get(labels, &1))
    labels_to_add = Enum.map(label_ids_to_add, &Map.get(labels, &1))
    {labels_to_remove, labels_to_add}
  end

  defp apply_team_policy_changes(access_token, repository, labels_to_remove, labels_to_add) do
    {team_policies_to_remove_only, team_policies_to_update, team_policies_to_add_only} =
      compute_team_policy_changes(labels_to_remove, labels_to_add)

    GitHub.Repositories.apply_repository_team_permission_changes(
      access_token,
      repository.owner.login,
      repository.name,
      team_policies_to_remove_only,
      team_policies_to_update,
      team_policies_to_add_only
    )
  end

  def compute_team_policy_changes(labels_to_remove, labels_to_add) do
    team_policies_to_remove =
      MapUtils.from_enum(labels_to_remove, fn label, map ->
        MapUtils.from_enum(
          label.team_policies,
          map,
          & &1.team_slug,
          &to_string(&1.permission)
        )
      end)

    team_policies_to_add =
      MapUtils.from_enum(labels_to_add, fn label, map ->
        MapUtils.from_enum(
          label.team_policies,
          map,
          & &1.team_slug,
          &to_string(&1.permission)
        )
      end)

    compute_team_policies_to_remove_add_update(team_policies_to_remove, team_policies_to_add)
  end

  def compute_team_policies_to_remove_add_update(team_policies_to_remove, team_policies_to_add) do
    {team_policies_to_remove_only, team_policies_to_update, team_policies_to_add_only} =
      MapUtils.delta(team_policies_to_remove, team_policies_to_add)

    unchanged_team_slugs =
      team_policies_to_update
      |> Map.keys()
      |> Enum.filter(fn team_slug ->
        Map.get(team_policies_to_remove, team_slug) ==
          Map.get(team_policies_to_update, team_slug)
      end)

    team_policies_to_update = Map.drop(team_policies_to_update, unchanged_team_slugs)

    {team_policies_to_remove_only, team_policies_to_update, team_policies_to_add_only}
  end

  defp apply_collaborator_changes(access_token, repository, labels_to_remove, labels_to_add) do
    collaborators_to_remove =
      MapUtils.from_enum(labels_to_remove, fn label, map ->
        MapUtils.from_enum(
          label.collaborator_policies,
          map,
          & &1.collaborator.id,
          &to_string(&1.permission)
        )
      end)

    collaborators_to_add =
      MapUtils.from_enum(labels_to_add, fn label, map ->
        MapUtils.from_enum(
          label.collaborator_policies,
          map,
          & &1.collaborator.id,
          &to_string(&1.permission)
        )
      end)

    {collaborators_to_remove_only, collaborators_to_update, collaborators_to_add_only} =
      MapUtils.delta(collaborators_to_remove, collaborators_to_add)

    unchanged_collaborators =
      collaborators_to_update
      |> Map.keys()
      |> Enum.filter(fn collaborator_id ->
        Map.get(collaborators_to_remove, collaborator_id) ==
          Map.get(collaborators_to_update, collaborator_id)
      end)

    collaborators_to_update = Map.drop(collaborators_to_update, unchanged_collaborators)

    GitHub.Repositories.apply_repository_collaborator_permission_changes(
      access_token,
      repository.owner.login,
      repository.name,
      collaborators_to_remove_only,
      collaborators_to_update,
      collaborators_to_add_only
    )
  end
end
