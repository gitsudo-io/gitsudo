defmodule GitHub.Repositories do
  @moduledoc """
  A set of functions for working with GitHub repositories.
  """

  import GitHub.Client

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
      Logger.debug("Removing team permission from #{org}/#{repo}: #{team_slug} => #{permission}")

      case remove_repository_from_team(
             access_token,
             org,
             team_slug,
             org,
             repo
           ) do
        {:ok, _} -> Logger.debug("Removed team permission: #{team_slug}")
        {:error, reason} -> Logger.error("Failed to remove team permission: #{inspect(reason)}")
      end
    end)

    Logger.debug("team_permissions_to_update => #{inspect(team_permissions_to_update)}")

    Enum.each(team_permissions_to_update, fn {team_slug, permission} ->
      Logger.debug("Updating team permission at #{org}/#{repo}: #{team_slug} => #{permission}")

      case put_team_repository_permissions(
             access_token,
             org,
             team_slug,
             org,
             repo,
             permission
           ) do
        {:ok, _} -> Logger.debug("Updated team permission for #{team_slug} to #{permission}")
        {:error, reason} -> Logger.error("Failed to remove team permission: #{inspect(reason)}")
      end
    end)

    Logger.debug("team_permissions_to_add_only => #{inspect(team_permissions_to_add_only)}")

    Enum.each(team_permissions_to_add_only, fn {team_slug, permission} ->
      Logger.debug("Adding team permission to #{org}/#{repo}: #{team_slug} => #{permission}")

      case put_team_repository_permissions(
             access_token,
             org,
             team_slug,
             org,
             repo,
             permission
           ) do
        {:ok, _} -> Logger.debug("Added team permission: #{team_slug} => #{permission}")
        {:error, reason} -> Logger.error("Failed to remove team permission: #{inspect(reason)}")
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

    Enum.each(collaborators_to_remove_only, fn {username, permission} ->
      Logger.debug("Removing collaborator from #{org}/#{repo}: #{username} => #{permission}")

      case remove_repository_collaborator(
             access_token,
             org,
             repo,
             username
           ) do
        {:ok, _} -> Logger.debug("Removed collaborator: #{username}")
        {:error, reason} -> Logger.error("Failed to remove collaborator: #{inspect(reason)}")
      end
    end)

    Enum.each(collaborators_to_update, fn {username, permission} ->
      Logger.debug("Updating collaborator at #{org}/#{repo}: #{username} => #{permission}")

      case add_repository_collaborator(
             access_token,
             org,
             repo,
             username,
             permission
           ) do
        {:ok, _} ->
          Logger.debug("Updated collaborator at #{org}/#{repo}: #{username} => #{permission}")

        {:error, reason} ->
          Logger.error("Failed to update collaborator: #{inspect(reason)}")
      end
    end)

    Enum.each(collaborators_to_add_only, fn {username, permission} ->
      Logger.debug("Adding collaborator to #{org}/#{repo}: #{username} => #{permission}")

      case add_repository_collaborator(
             access_token,
             org,
             repo,
             username,
             permission
           ) do
        {:ok, _} ->
          Logger.debug("Added collaborator to #{org}/#{repo}: #{username} => #{permission}")

        {:error, reason} ->
          Logger.error("Failed to add collaborator: #{inspect(reason)}")
      end
    end)
  end
end
