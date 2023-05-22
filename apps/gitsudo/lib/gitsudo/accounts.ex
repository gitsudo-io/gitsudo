defmodule Gitsudo.Accounts do
  @moduledoc """
  The Accounts context
  """
  import Ecto.Query, warn: false
  alias Gitsudo.Accounts.{Account, UserSession}
  alias Gitsudo.Repo

  require Logger

  @spec get_account(id :: integer()) :: Account | nil
  def get_account(id) do
    Repo.get(Account, id)
  end

  def find_or_fetch_account(organization, login) do
    case get_account_by_login(login) do
      nil ->
        Logger.debug("Fetching account with login \"#{login}\"...")

        with {:ok, access_token} <-
               Gitsudo.Organizations.get_access_token_for_org(organization.id),
             {:ok, user_data} <- GitHub.Client.get_user(access_token, login) do
          create_account_from_json(user_data)
        else
          {:error, reason} -> Logger.error(reason)
        end

      account ->
        Logger.debug("Found account with login \"#{login}\"...")
        {:ok, account}
    end
  end

  def create_account_from_json(
        %{"id" => account_id, "login" => login, "type" => type} = user_data
      ) do
    Account.new(%{
      id: account_id,
      login: login,
      type: type
    })
    |> Repo.insert()
  end

  @spec get_account_by_login(login :: String.t()) ::
          Account | term() | nil
  def get_account_by_login(login) do
    Repo.get_by(Account, login: login)
  end

  @spec find_or_create_account(any, map) :: {:ok, Account} | {:error, Ecto.Changeset.t()}
  def find_or_create_account(account_id, %{"login" => login, "type" => type} = attrs) do
    Logger.debug("find_or_create_account(#{account_id}, %{login: #{login}, type: #{type}})")

    account = Repo.get(Account, account_id) || %Account{id: account_id}

    account
    |> Account.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @spec handle_user_login(
          client_id :: String.t(),
          client_secret :: String.t(),
          code :: String.t()
        ) ::
          {:ok, map()} | {:error, Exception.t() | Jason.DecodeError.t()}
  def handle_user_login(client_id, client_secret, code) do
    with {:ok, json} <-
           GitHub.Client.exchange_code_for_access_token(client_id, client_secret, code) do
      handle_exchange_code_for_access_token_json(json)
    end
  end

  defp handle_exchange_code_for_access_token_json(%{
         "access_token" => access_token,
         "expires_in" => expires_in,
         "refresh_token" => refresh_token,
         "refresh_token_expires_in" => refresh_token_expires_in
       }) do
    now = :os.system_time(:seconds)
    expires_at_unix = now + expires_in
    refresh_token_expires_at_unix = now + refresh_token_expires_in

    with {:ok, expires_at} <- DateTime.from_unix(expires_at_unix),
         {:ok, refresh_token_expires_at} <-
           DateTime.from_unix(refresh_token_expires_at_unix),
         {:ok, %{"id" => id} = github_user} <- GitHub.Client.get_user(access_token) do
      Logger.debug("Found user: #{inspect(github_user)}")

      with {:ok, user} <- create_or_update_user(github_user),
           {:ok, _user_session} <-
             create_or_update_user_session(id, %{
               access_token: access_token,
               expires_at: expires_at,
               refresh_token: refresh_token,
               refresh_token_expires_at: refresh_token_expires_at
             }) do
        {:ok, %{user_id: user.id, exp: expires_at_unix}}
      end
    end
  end

  defp handle_exchange_code_for_access_token_json(%{
         "error" => _error,
         "error_description" => error_description
       }),
       do: {:error, error_description}

  @spec create_or_update_user(map) :: {:ok, Account} | {:error, Ecto.Changeset.t()}
  def create_or_update_user(%{"id" => id, "login" => login, "type" => type} = user_data) do
    Logger.debug(
      "create_or_update_user(#{inspect(%{"id" => id, "login" => login, "type" => type})})"
    )

    account = Repo.get(Account, id) || %Account{id: id}

    account
    |> Account.changeset(user_data)
    |> Repo.insert_or_update()
  end

  @spec get_user_session(user_id :: integer()) :: %UserSession{} | nil
  def get_user_session(user_id) do
    Repo.get(UserSession, user_id) |> Repo.preload(:user)
  end

  @spec create_or_update_user_session(
          integer(),
          map()
        ) :: {:ok, UserSession} | {:error, Ecto.Changeset.t()}
  def create_or_update_user_session(
        user_id,
        data
      ) do
    session = Repo.get(UserSession, user_id) || %UserSession{id: user_id}

    session
    |> UserSession.changeset(data)
    |> Repo.insert_or_update()
  end

  @doc """
  List user installations
  """
  @spec list_user_installations(user :: %Account{}) ::
          {:ok, list()} | {:error, any()}
  def list_user_installations(user) do
    with user_session <- get_user_session(user.id) do
      case GitHub.Client.list_user_installations(user_session.access_token) do
        {:ok, %{"installations" => installations}} -> {:ok, installations}
        {:ok, _} -> {:error, "Unexpected response from GitHub"}
        {:error, reason} -> {:error, reason}
      end
    end
  end
end
