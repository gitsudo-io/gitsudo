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
    Logger.debug("access_token => #{inspect(access_token)}")
    Logger.debug("label_before => #{inspect(label_before)}")
    Logger.debug("label_after => #{inspect(label_after)}")

    repositories_to_apply_to = label_before.repositories

    Logger.debug(
      "repositories_to_apply_to => #{inspect(repositories_to_apply_to |> Enum.map(& &1.name))}"
    )

    if !Enum.empty?(repositories_to_apply_to) do
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

      Enum.each(repositories_to_apply_to, fn repository ->
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

    {:ok, label_after}
  end
end
