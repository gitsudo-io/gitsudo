defmodule Gitsudo.Accounts do
  @moduledoc """
  The Accounts context
  """
  import Ecto.Query, warn: false
  alias Gitsudo.Accounts.{Account, UserSession}
  alias Gitsudo.Repo

  require Logger

  @spec get_account_by_login(login :: String.t()) ::
          %Account{} | term() | nil
  def get_account_by_login(login) do
    Repo.get_by(Account, login: login)
  end

  @spec find_or_create_account(any, map) :: any
  def find_or_create_account(account_id, %{"login" => login, "type" => type}) do
    Logger.debug("find_or_create_account(#{account_id}, %{login: #{login}, type: #{type}})")

    account = Repo.get(Account, account_id) || %Account{id: account_id}

    account
    |> Account.changeset(%{id: account_id, login: login, type: type})
    |> Repo.insert_or_update()
  end

  @spec handle_user_login(
          client_id :: String.t(),
          client_secret :: String.t(),
          code :: String.t()
        ) ::
          {:ok, %{access_token: String.t(), exp: integer()}}
          | {:error, Exception.t() | Jason.DecodeError.t()}
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
         {:ok, %{"id" => id} = user} <- GitHub.Client.get_user(access_token) do
      Logger.debug("Found user: #{inspect(user)}")

      with {:ok, _user_session} <-
             create_or_update_user_session(id, %{
               access_token: access_token,
               expires_at: expires_at,
               refresh_token: refresh_token,
               refresh_token_expires_at: refresh_token_expires_at
             }) do
        {:ok, %{access_token: access_token, exp: expires_at_unix}}
      end
    end
  end

  defp handle_exchange_code_for_access_token_json(%{
         "error" => _error,
         "error_description" => error_description
       }),
       do: {:error, error_description}

  @spec create_or_update_user_session(
          integer(),
          map()
        ) :: {:ok, %UserSession{}} | {:error, %Ecto.Changeset{}}
  def create_or_update_user_session(
        user_id,
        data
      ) do
    session = Repo.get(UserSession, user_id) || %UserSession{id: user_id}

    session
    |> UserSession.changeset(data)
    |> Repo.insert_or_update()
  end
end
