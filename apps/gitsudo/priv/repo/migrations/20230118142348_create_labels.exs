defmodule Gitsudo.Repo.Migrations.CreateLabels do
  use Ecto.Migration

  def change do
    create table(:labels) do
      add :name, :string
      add :color, :string

      timestamps()
    end
  end
end
