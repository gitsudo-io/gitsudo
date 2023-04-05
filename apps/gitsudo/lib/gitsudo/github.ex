defmodule Gitsudo.GitHub do
  @moduledoc """
  The GitHub context
  """
  import Ecto.Query, warn: false
  alias Gitsudo.Repo

  alias Gitsudo.GitHub.AppInstallation
  alias Gitsudo.Accounts

  require Logger

  @doc """
  Persist a GitHub App installation record.
  """
  @spec create_app_installation(data :: map) :: {:ok, AppInstallation} | {:error, any}
  def create_app_installation(%{"id" => installation_id} = installation)
      when is_integer(installation_id) and is_map(installation) do
    Logger.debug("create_app_installation(id: #{installation_id})")
    Logger.debug(inspect(installation))

    with %{
           "account" => account,
           "access_tokens_url" => access_tokens_url
         } <-
           installation,
         {:ok, app_installation} <-
           create_app_installation_and_account(installation_id, account, access_tokens_url) do
      Logger.debug("app_installation: #{inspect(app_installation)}")

      case GitHub.TokenCache.get_or_refresh_token(installation_id) do
        {:ok, token} ->
          Logger.debug("token: #{inspect(token)}")

          case GitHub.Client.list_org_repos(token, account["login"]) do
            {:ok, repos} ->
              Enum.each(repos, &Gitsudo.Repositories.create_repository/1)

            {:error, reason} ->
              Logger.error(reason)
          end

        {:error, reason} ->
          Logger.error(reason)
      end

      {:ok, app_installation}
    end
  end

  @spec create_app_installation_and_account(integer(), map, String.t()) ::
          {:ok, any()} | {:error, any}
  def create_app_installation_and_account(
        installation_id,
        %{"id" => account_id} = account,
        access_tokens_url
      ) do
    Repo.transaction(fn ->
      with {:ok, account} <- Accounts.find_or_create_account(account_id, account) do
        Logger.debug("account: #{inspect(account)}")

        %AppInstallation{}
        |> AppInstallation.changeset(%{
          id: installation_id,
          account_id: account.id,
          access_tokens_url: access_tokens_url
        })
        |> Repo.insert!()
      end
    end)
  end
end
