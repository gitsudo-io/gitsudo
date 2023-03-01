defmodule Gitsudo.Repositories do
  @moduledoc """
  The Repositories context.
  """

  import Ecto.Query, warn: false

  alias Gitsudo.Repositories
  alias Gitsudo.Repo
  alias Gitsudo.Repositories.Repository

  require Logger

  @doc """
  List all user's repositories
  """
  @spec list_user_repositories(user :: map(), access_token :: String.t()) ::
          {:ok, list()} | {:error, any()}
  def list_user_repositories(_user, access_token) do
    with {:ok, orgs} <- GitHub.Client.list_user_orgs(access_token),
         {:ok, repos} <- list_user_repositories_for_orgs(access_token, orgs) do
      Logger.debug("Found #{length(repos)} user repos")
      {:ok, enrich_repos_with_labels_and_config_sets(repos)}
    end
  end

  @spec list_user_repositories_for_orgs(access_token :: String.t(), orgs :: list()) ::
          {:ok, list()} | {:error, any()}
  def list_user_repositories_for_orgs(access_token, orgs) do
    Logger.debug("Found #{length(orgs)} user orgs")

    Enum.reduce_while(orgs, {:ok, []}, fn org, {:ok, repos} ->
      Logger.debug(~s'org["login"]: #{org["login"]}')

      with {:ok, org_repos} <- GitHub.Client.list_org_repos(access_token, org["login"]) do
        Logger.debug(~s[Found #{length(org_repos)} repos under #{org["login"]}}])
        {:cont, {:ok, repos ++ org_repos}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  @spec enrich_repos_with_labels_and_config_sets(list()) :: list()
  def enrich_repos_with_labels_and_config_sets(repos) do
    Enum.map(repos, &Repositories.enrich_repo/1)
  end

  @spec enrich_repo(map()) :: map()
  def enrich_repo(repo) do
    repo
    |> Map.put_new("labels", [])
    |> Map.put_new("config_sets_applied", [])
  end

  @doc """
  Get repository by owner_id and name
  """
  @spec get_repository_by_owner_id_and_name(owner_id :: integer(), name :: String.t()) :: any
  def get_repository_by_owner_id_and_name(owner_id, name) do
    Repo.get_by(Repository, owner_id: owner_id, name: name)
  end

  @doc """
  Create a Repository record.
  """
  def create_repository(%{"id" => id, "name" => name, "owner" => owner} = _args) do
    Logger.debug(
      ~s[create_repository(%{"id" => #{id}, "name" => #{name}, "owner" => #{inspect(owner)}} = _args)]
    )

    %Repository{}
    |> Repository.changeset(%{id: id, name: name, owner_id: owner["id"]})
    |> Repo.insert()
  end
end
