defmodule Gitsudo.Repositories do
  @moduledoc """
  The Repositories context.
  """

  import Ecto.Query, warn: false

  alias Gitsudo.Labels
  alias Gitsudo.Repositories
  alias Gitsudo.Repo
  alias Gitsudo.Repositories.Repository
  alias Gitsudo.Labels.Label

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
  defp list_user_repositories_for_orgs(access_token, orgs) do
    Logger.debug("Found #{length(orgs)} user orgs")

    Enum.reduce_while(orgs, {:ok, []}, fn org, {:ok, repos} ->
      Logger.debug(~s'org["login"]: #{org["login"]}')
      list_user_repositories_for_org(access_token, repos, org["login"])
    end)
  end

  defp list_user_repositories_for_org(access_token, repos, org) do
    case GitHub.Client.list_org_repos(access_token, org) do
      {:ok, org_repos} ->
        Logger.debug(~s'Found #{length(org_repos)} repos under "#{org}"}')
        {:cont, {:ok, repos ++ org_repos}}

      {:error, reason} ->
        handle_list_user_repositories_for_org_error(reason, repos)
    end
  end

  # Ignore "403 Forbidden" on an org
  defp handle_list_user_repositories_for_org_error("403 Forbidden", repos),
    do: {:cont, {:ok, repos}}

  defp handle_list_user_repositories_for_org_error(reason, _) do
    Logger.error(if(is_binary(reason), do: reason, else: inspect(reason)))
    {:halt, {:error, reason}}
  end

  @spec enrich_repos_with_labels_and_config_sets(list()) :: list()
  def enrich_repos_with_labels_and_config_sets(repos) do
    Enum.map(repos, fn repo_data ->
      with {:ok, repository} <- Repositories.find_or_create_repository(repo_data) do
        repository
      end
    end)
  end

  @spec find_or_create_repository(map()) :: {:ok, %Repository{}} | {:error, any()}
  def find_or_create_repository(%{"id" => id, "owner" => owner} = repo) do
    Logger.debug("repo: #{inspect(repo)}")

    if repository = Repo.get(Repository, id) |> Repo.preload([:owner, :labels]) do
      Logger.debug("Found repository: #{inspect(repository)}")
      {:ok, repository}
    else
      with {:ok, repository} <- create_repository(repo) do
        {:ok, Repo.preload(repository, [:owner, :labels])}
      end
    end
  end

  @doc """
  Get repository by owner_id and name
  """
  @spec get_repository_by_owner_id_and_name(owner_id :: integer(), name :: String.t()) ::
          nil | %Repository{}
  def get_repository_by_owner_id_and_name(owner_id, name, options \\ [preload: [:owner, :labels]]) do
    Logger.debug("preload: #{inspect(Keyword.get(options, :preload, [:owner, :labels]))}")

    Repository
    |> Repo.get_by(owner_id: owner_id, name: name)
    |> Repo.preload(Keyword.get(options, :preload, [:owner, :labels]))
  end

  @doc """
  Create a Repository record.
  """
  def create_repository(%{"id" => id, "name" => name, "owner" => owner} = attrs, opts \\ []) do
    Logger.debug(
      ~s[create_repository(%{"id" => #{id}, "name" => #{name}, "owner" => #{inspect(owner)}})]
    )

    with {:ok, repository} <-
           %Repository{id: id, owner_id: owner["id"]}
           |> Repository.changeset(attrs)
           |> Repo.insert() do
      if Keyword.has_key?(opts, :preload) do
        {:ok, Repo.preload(repository, Keyword.get(opts, :preload))}
      else
        {:ok, repository}
      end
    end
  end

  ########################################################
  # Labels
  ########################################################

  @doc """
  Add a label to a repository.
  """
  @spec add_label_to_repository(repository :: %Repository{}, label :: %Label{}) :: any
  def add_label_to_repository(repository, label) do
    repository = Repo.preload(repository, [:labels])
    labels = [label | repository.labels]

    with {:ok, repository} <-
           Ecto.Changeset.change(repository)
           |> Ecto.Changeset.put_assoc(:labels, labels)
           |> Repo.update() do
      {:ok, Repo.preload(repository, [:labels])}
    end
  end

  @change_labels_default_preload [
    :owner,
    labels: [:team_policies, collaborator_policies: [:collaborator]]
  ]

  @spec change_labels(repository :: %Repository{}, changes :: map(), opts :: Keyword.t()) ::
          {:ok, %Repository{}} | {:error, any()}
  def change_labels(repository, changes, opts \\ []) do
    Logger.debug("changes: #{inspect(changes)}")

    preload = opts |> Keyword.get(:preload, @change_labels_default_preload)

    repository = Repo.preload(repository, preload)

    Logger.debug("labels before: #{inspect(repository.labels)}")

    label_ids_to_remove = Map.get(changes, "labelsToRemove", [])
    label_ids_to_add = Map.get(changes, "labelsToAdd", [])

    if Enum.empty?(label_ids_to_remove) && Enum.empty?(label_ids_to_add) do
      {:ok, repository}
    else
      with {:ok, new_labels} <- apply_changes(repository, changes),
           {:ok, repository} <-
             Ecto.Changeset.change(repository)
             |> Ecto.Changeset.put_assoc(:labels, new_labels)
             |> Repo.update() do
        Logger.debug("labels after: #{inspect(new_labels)}")

        Gitsudo.Events.repository_labels_changed(repository, %{
          label_ids_to_remove: label_ids_to_remove,
          label_ids_to_add: label_ids_to_add
        })

        {:ok, Repo.preload(repository, preload)}
      end
    end
  end

  defp apply_changes(%{owner: %{id: owner_id}} = repository, changes) do
    label_ids_to_remove = Map.get(changes, "labelsToRemove", [])
    label_ids_to_add = Map.get(changes, "labelsToAdd", [])

    repository.labels
    |> remove_labels(label_ids_to_remove)
    |> add_labels(owner_id, label_ids_to_add)
  end

  defp remove_labels(labels, label_ids_to_remove) do
    Enum.reduce(label_ids_to_remove, labels, fn label_id, labels ->
      Enum.reject(labels, &(&1.id == label_id))
    end)
  end

  def add_labels(labels, owner_id, label_ids_to_add) do
    Enum.reduce_while(label_ids_to_add, {:ok, labels}, fn label_id, {:ok, labels} ->
      case Labels.get_label(owner_id, label_id) do
        %Label{} = label ->
          {:cont, {:ok, [label | labels]}}

        nil ->
          {:halt, {:error, "Label id #{label_id} not found"}}
      end
    end)
  end
end
