defmodule Gitsudo.Accounts do
  @moduledoc """
  The Accounts context
  """
  import Ecto.Query, warn: false
  alias Gitsudo.Accounts.Account
  alias Gitsudo.Repo

  require Logger

  @spec find_or_create_account(any, map) :: any
  def find_or_create_account(account_id, %{"login" => login, "type" => type}) do
    Logger.debug("find_or_create_account(account_id, %{login: #{login}, type: #{type}})")

    account = Repo.get(Account, account_id) || %Account{id: account_id}

    account
    |> Account.changeset(%{id: account_id, login: login, type: type})
    |> Repo.insert_or_update()
  end
end
