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
    with {:ok, org_repos} <- GitHub.Client.list_org_repos(access_token, organization.login) do
      Logger.debug(~s'Found #{length(org_repos)} repos under "#{organization.login}"}')
      {:ok, Repositories.enrich_repos_with_labels_and_config_sets(org_repos)}
    end
  end

  def get_access_token_for_org(account_id) do
    if app_installation = Repo.get_by(Gitsudo.GitHub.AppInstallation, account_id: account_id) do
      GitHub.TokenCache.get_or_refresh_token(app_installation.id)
    else
      {:error, "No app_installation found for account_id #{account_id}"}
    end
  end
end
