defmodule Gitsudo.Repo.Migrations.CreateRepositoryOwners do
  use Ecto.Migration

  def change do
    create table(:repository_owners, primary_key: false) do
      add :id, :integer, primary_key: true

      add :login, :string, null: false
      add :type, :string, null: false

      timestamps()
    end

    create unique_index(:repository_owners, [:login])
  end
end
