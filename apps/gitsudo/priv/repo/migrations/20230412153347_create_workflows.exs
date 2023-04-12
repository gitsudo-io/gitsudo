defmodule Gitsudo.Repo.Migrations.CreateWorkflows do
  use Ecto.Migration

  def change do
    create table(:workflows, primary_key: false) do
      add :id, :integer, primary_key: true

      add :repository_id,
          references(:repositories, type: :integer, on_delete: :delete_all, null: false)

      add :name, :string, null: false
      add :path, :string, null: false

      timestamps()
    end

    create index(:workflows, [:repository_id])
  end
end
