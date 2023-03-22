defmodule Gitsudo.Accounts.UserSession do
  @moduledoc """
  A GitHub user session stores the temporary access token and refresh tokens
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "user_sessions" do
    field :access_token, :string
    field :expires_at, :utc_datetime
    field :refresh_token, :string
    field :refresh_token_expires_at, :utc_datetime

    timestamps()
  end

  @doc false
  @spec changeset(map(), map()) :: Ecto.Changeset.t()
  def changeset(user_session, attrs) do
    user_session
    |> cast(attrs, [:access_token, :expires_at, :refresh_token, :refresh_token_expires_at])
    |> validate_required([:access_token, :expires_at, :refresh_token, :refresh_token_expires_at])
  end
end
