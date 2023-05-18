defmodule GitHub.Repositories do
  @moduledoc """
  A set of functions for working with GitHub repositories.
  """

  alias GitHub.Client

  require Logger

  @doc """
  Apply a set of team permission changes to a repository.
  """
  def apply_repository_team_permission_changes(
        access_token,
        org,
        repo,
        team_permissions_to_remove_only,
        team_permissions_to_update,
        team_permissions_to_add_only
      ) do
    Logger.debug("team_permissions_to_remove_only => #{inspect(team_permissions_to_remove_only)}")

    Enum.each(team_permissions_to_remove_only, fn {team_slug, permission} ->
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

    Logger.debug("team_permissions_to_update => #{inspect(team_permissions_to_update)}")

    Enum.each(team_permissions_to_update, fn {team_slug, permission} ->
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

    Logger.debug("team_permissions_to_add_only => #{inspect(team_permissions_to_add_only)}")

    Enum.each(team_permissions_to_add_only, fn {team_slug, permission} ->
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

  @doc """
  Apply a set of team permission changes to a repository.
  """
  def apply_repository_collaborator_permission_changes(
        access_token,
        org,
        repo,
        collaborators_to_remove_only,
        collaborators_to_update,
        collaborators_to_add_only
      ) do
    Logger.debug("collaborators_to_remove_only => #{inspect(collaborators_to_remove_only)}")
    Logger.debug("collaborators_to_update => #{inspect(collaborators_to_update)}")
    Logger.debug("collaborators_to_add_only => #{inspect(collaborators_to_add_only)}")
  end
end
