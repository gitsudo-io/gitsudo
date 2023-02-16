defmodule Gitsudo.Repo.Migrations.CreateAppInstallations do
  use Ecto.Migration

  def change do
    create table(:app_installations, primary_key: false) do
      add :id, :integer, primary_key: true

      add :access_tokens_url, :string

      add :account_id,
          references(:repository_owners, type: :integer, on_delete: :nothing, null: false)

      timestamps()
    end
  end
end
