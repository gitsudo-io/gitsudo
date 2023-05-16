defmodule Gitsudo.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :integer, primary_key: true

      add :login, :string, null: false
      add :type, :string, null: false
      add :html_url, :string
      add :avatar_url, :string

      timestamps()
    end

    create unique_index(:accounts, [:login])
  end
end
