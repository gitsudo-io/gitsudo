defmodule GitHub.Policies.TeamPolicy do
  @moduledoc """
  Defines/applies a team policy to a repository.
  """

  defstruct [:team_slug, :permission]

  alias GitHub.Client

  @doc """
  Applies this policy using GitHub API.
  """
  @spec apply(access_token :: String.t(), policy :: %__MODULE__{}, repository_id :: integer()) ::
          {:ok, nil} | {:error, any()}
  def apply(
        access_token,
        %__MODULE__{team_slug: team_slug, permission: permission} = _policy,
        repository_id
      ) do
    with {:ok, %{"name" => repo, "owner" => %{"login" => org}} = _repository} <-
           Client.get_repository_by_id(access_token, repository_id),
         {:ok, _team} <- Client.get_team(access_token, org, team_slug) do
      Client.put_team_repository_permissions(access_token, org, team_slug, org, repo, permission)
    end
  end
end
