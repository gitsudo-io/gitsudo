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

    apply_team_policy_changes(access_token, repository, labels_to_remove, labels_to_add)

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

    org = repository.owner.login
    repo = repository.name

    Logger.debug("team_policies_to_remove_only => #{inspect(team_policies_to_remove_only)}")

    Enum.each(team_policies_to_remove_only, fn {team_slug, permission} ->
      Logger.debug(
        "Removing team permission: #{inspect(team_slug)} => #{inspect(permission)} to #{org}/#{repo}"
      )

      case GitHub.Client.remove_repository_from_team(
             access_token,
             org,
             team_slug,
             org,
             repo
           ) do
        {:error, reason} -> Logger.error("Failed to remove team permission: #{inspect(reason)}")
        {:ok, _} -> Logger.debug("Removed team permission: #{inspect(team_slug)}")
      end
    end)

    Logger.debug("team_policies_to_update => #{inspect(team_policies_to_update)}")

    Enum.each(team_policies_to_update, fn {team_slug, permission} ->
      Logger.debug(
        "Updating team permission: #{inspect(team_slug)} => #{inspect(permission)} to #{org}/#{repo}"
      )

      case GitHub.Client.put_team_repository_permissions(
             access_token,
             org,
             team_slug,
             org,
             repo,
             permission
           ) do
        {:error, reason} -> Logger.error("Failed to remove team permission: #{inspect(reason)}")
        {:ok, _} -> Logger.debug("Removed team permission: #{inspect(team_slug)}")
      end
    end)

    Logger.debug("team_policies_to_add_only => #{inspect(team_policies_to_add_only)}")

    Enum.each(team_policies_to_add_only, fn {team_slug, permission} ->
      Logger.debug(
        "Adding team permission: #{inspect(team_slug)} => #{inspect(permission)} to #{org}/#{repo}"
      )

      case GitHub.Client.put_team_repository_permissions(
             access_token,
             org,
             team_slug,
             org,
             repo,
             permission
           ) do
        {:error, reason} -> Logger.error("Failed to remove team permission: #{inspect(reason)}")
        {:ok, _} -> Logger.debug("Removed team permission: #{inspect(team_slug)}")
      end
    end)
  end

  def compute_team_policy_changes(labels_to_remove, labels_to_add) do
    team_policies_to_remove =
      MapUtils.from_enum(labels_to_remove, fn label, to_remove ->
        Enum.reduce(label.team_policies, to_remove, fn tp, to_remove ->
          Map.put(to_remove, tp.team_slug, tp.permission)
        end)
      end)

    team_policies_to_add =
      MapUtils.from_enum(labels_to_add, fn label, to_add ->
        Enum.reduce(label.team_policies, to_add, fn tp, to_add ->
          Map.put(to_add, tp.team_slug, tp.permission)
        end)
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
        Map.get(team_policies_to_remove_only, team_slug) ==
          Map.get(team_policies_to_update, team_slug)
      end)

    team_policies_to_update = Map.drop(team_policies_to_update, unchanged_team_slugs)

    {team_policies_to_remove_only, team_policies_to_update, team_policies_to_add_only}
  end
end
