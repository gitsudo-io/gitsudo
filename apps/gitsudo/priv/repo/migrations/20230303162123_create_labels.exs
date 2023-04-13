defmodule Gitsudo.Repo.Migrations.CreateLabels do
  use Ecto.Migration

  def change do
    create table(:labels) do
      add :owner_id,
          references(:accounts, type: :integer, on_delete: :delete_all, null: false)

      add :name, :string, null: false
      add :color, :string, null: false
      add :description, :string

      timestamps()
    end

    create unique_index(:labels, [:owner_id, :name])
  end
end
