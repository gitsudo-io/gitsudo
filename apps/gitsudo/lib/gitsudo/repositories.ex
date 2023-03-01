defmodule Gitsudo.Repositories do
  @moduledoc """
  The Repositories context.
  """

  import Ecto.Query, warn: false

  alias Gitsudo.Repo
  alias Gitsudo.Repositories.Repository

  require Logger

  @doc """
  List all user's repositories
  """
  def list_user_repositories(_user, access_token) do
    with {:ok, orgs} <- GitHub.Client.list_user_orgs(access_token) do
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
