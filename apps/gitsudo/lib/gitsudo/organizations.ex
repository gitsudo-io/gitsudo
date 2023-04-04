defmodule Gitsudo.Organizations do
  @moduledoc """
  The Organizations context.
  """

  import Ecto.Query, warn: false

  alias Gitsudo.Repositories
  alias Gitsudo.Repo

  require Logger

  @spec get_organization(String.t()) :: any
  def get_organization(name) do
    Repo.get_by(Gitsudo.Accounts.Account, type: "Organization", login: name)
  end

  def list_repositories(access_token, organization) do
    case GitHub.Client.list_org_repos(access_token, organization.login) do
      {:ok, org_repos} ->
        Logger.debug(~s'Found #{length(org_repos)} repos under "#{organization.login}"}')
        {:ok, Repositories.enrich_repos_with_labels_and_config_sets(org_repos)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
