defmodule Gitsudo.GitHub do
  @moduledoc """
  The GitHub context
  """
  import Ecto.Query, warn: false
  alias Gitsudo.Repo

  alias Gitsudo.GitHub.AppInstallation
  alias Gitsudo.Accounts

  require Logger

  @spec create_app_installation(map) :: any
  def create_app_installation(
        %{"action" => "created", "installation" => %{"id" => installation_id} = installation} =
          _data
      )
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

      with {:ok, token} <-
             GitHub.TokenCache.get_or_refresh_token(installation_id) do
        Logger.debug("token: #{inspect(token)}")

        with {:ok, repos} <- GitHub.Client.list_org_repos(token, account["login"]) do
          Enum.each(repos, &Gitsudo.Repositories.create_repository/1)
        else
          {:error, reason} -> Logger.error(reason)
        end
      else
        {:error, reason} -> Logger.error(reason)
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