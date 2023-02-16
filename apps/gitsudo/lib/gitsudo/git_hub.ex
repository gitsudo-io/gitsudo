defmodule Gitsudo.GitHub do
  @moduledoc """
  The GitHub context
  """
  import Ecto.Query, warn: false
  alias Gitsudo.Repo

  alias Gitsudo.GitHub.{AppInstallation}
  alias Gitsudo.Repositories.Owner

  require Logger

  def create_app_installation(
        %{"action" => "created", "installation" => %{"id" => id} = installation} = _data
      )
      when is_integer(id) and is_map(installation) do
    Logger.debug("create_app_installation(id: #{id})")
    Logger.debug(inspect(installation))

    Repo.transaction(fn ->
      with %{
             "account" => %{"id" => account_id} = account,
             "access_tokens_url" => access_tokens_url
           } <-
             installation,
           account <- find_or_create_account(account_id, account) do
        Logger.debug("account: #{inspect(account)}")

        created =
          %AppInstallation{}
          |> AppInstallation.changeset(%{
            id: id,
            account_id: account.id,
            access_tokens_url: access_tokens_url
          })
          |> Repo.insert!()

        Logger.debug(inspect(created))
      end
    end)
  end

  def find_or_create_account(account_id, %{"login" => login, "type" => type}) do
    Repo.get(Owner, account_id) ||
      %Owner{}
      |> Owner.changeset(%{id: account_id, login: login, type: type})
      |> Repo.insert!()
  end
end
