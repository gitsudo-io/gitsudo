defmodule Gitsudo.Repo.Migrations.CreateUserSessions do
  use Ecto.Migration

  def change do
    create table(:user_sessions, primary_key: false) do
      add :id, :integer, primary_key: true

      add :access_token, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :refresh_token, :string, null: false
      add :refresh_token_expires_at, :utc_datetime, null: false

      timestamps()
    end
  end
end
