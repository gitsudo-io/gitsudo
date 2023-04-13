defmodule Gitsudo.Repo.Migrations.CreateRepositoriesLabels do
  use Ecto.Migration

  def change do
    create table(:repositories_labels) do
      add :repository_id, references(:repositories, on_delete: :delete_all, null: false)
      add :label_id, references(:labels, on_delete: :delete_all, null: false)
    end

    create unique_index(:repositories_labels, [:repository_id, :label_id])
  end
end
