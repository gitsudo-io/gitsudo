defmodule Gitsudo.Repo.Migrations.CreateLabels do
  use Ecto.Migration

  def change do
    create table(:labels) do
      add :owner_id,
          references(:accounts, type: :integer, on_delete: :nothing, null: false)

      add :name, :string, null: false
      add :color, :string, null: false
      add :description, :string

      timestamps()
    end
  end
end
