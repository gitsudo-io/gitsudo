defmodule GitsudoWeb.UserSessionFixtures do
  @moduledoc """
  This module defines test helpers for creating a User and a UserSession for testing.
  """

  @dummy_personal_access_token "06d5607433ef55fbfd842fd06ee740eddec4caaf"

  @doc """
  Create a User and a UserSession for testing.
  """
  def user_session_fixture() do
    {:ok, account} =
      Gitsudo.Accounts.find_or_create_account(121_780_924, %{
        "login" => "gitsudo-io",
        "type" => "Organization"
      })

    tomorrow = DateTime.utc_now() |> DateTime.add(1, :day)

    {:ok, user_session} =
      Gitsudo.Accounts.create_or_update_user_session(account.id, %{
        access_token: @dummy_personal_access_token,
        expires_at: tomorrow,
        refresh_token: "dummy_refresh_token",
        refresh_token_expires_at: tomorrow
      })

    user_session
  end
end
