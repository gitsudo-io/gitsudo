defmodule Gitsudo.Events.RepositoryLabelsChanged do
  @moduledoc """
  The handler or actual worker code for the LabelsChanged event. Called by Gitsudo.Events.AsyncWorker.
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

    apply_team_policy_changes(repository, labels_to_remove, labels_to_add)

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

  defp apply_team_policy_changes(repository, labels_to_remove, labels_to_add) do
    {team_policies_to_remove_only, team_policies_to_update, team_policies_to_add_only} =
      compute_team_policy_changes(labels_to_remove, labels_to_add)
  end

  def compute_team_policy_changes(labels_to_remove, labels_to_add) do
    team_policies_to_remove =
      Enum.reduce(labels_to_remove, %{}, fn label, to_remove ->
        Enum.reduce(label.team_policies, to_remove, fn tp, to_remove ->
          Map.put(to_remove, tp.team_slug, tp.permission)
        end)
      end)

    team_policies_to_add =
      Enum.reduce(labels_to_add, %{}, fn label, to_add ->
        Enum.reduce(label.team_policies, to_add, fn tp, to_add ->
          Map.put(to_add, tp.team_slug, tp.permission)
        end)
      end)

    {team_policies_to_remove_only, team_policies_to_update, team_policies_to_add_only} =
      compute_team_policies_to_remove_add_update(team_policies_to_remove, team_policies_to_add)
  end

  def compute_team_policies_to_remove_add_update(team_policies_to_remove, team_policies_to_add) do
    team_slugs_to_remove = team_policies_to_remove |> Map.keys() |> MapSet.new()
    team_slugs_to_add = team_policies_to_add |> Map.keys() |> MapSet.new()
    team_slugs_to_update = MapSet.intersection(team_slugs_to_remove, team_slugs_to_add)

    team_policies_to_update =
      Enum.reduce(team_slugs_to_update, %{}, fn team_slug, to_update ->
        permission_to_remove = Map.get(team_policies_to_remove, team_slug)
        permission_to_add = Map.get(team_policies_to_add, team_slug)

        if permission_to_remove == permission_to_add do
          to_update
        else
          Map.put(to_update, team_slug, permission_to_add)
        end
      end)

    team_policies_to_remove_only =
      MapSet.difference(team_slugs_to_remove, team_slugs_to_update)
      |> Enum.reduce(%{}, fn team_slug, to_remove ->
        Map.put(to_remove, team_slug, Map.get(team_policies_to_remove, team_slug))
      end)

    team_policies_to_add_only =
      MapSet.difference(team_slugs_to_add, team_slugs_to_update)
      |> Enum.reduce(%{}, fn team_slug, to_add ->
        Map.put(to_add, team_slug, Map.get(team_policies_to_add, team_slug))
      end)

    {team_policies_to_remove_only, team_policies_to_update, team_policies_to_add_only}
  end
end
