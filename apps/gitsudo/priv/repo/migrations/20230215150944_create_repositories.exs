defmodule Gitsudo.Repo.Migrations.CreateRepositories do
  use Ecto.Migration

  def change do
    create table(:repositories, primary_key: false) do
      add :id, :integer, primary_key: true

      add :owner_id,
          references(:accounts, type: :integer, on_delete: :nothing, null: false)

      add :name, :string, null: false
      add :html_url, :string, null: false

      timestamps()
    end

    create unique_index(:repositories, [:owner_id, :name])
    create index(:repositories, [:owner_id])
  end
end
