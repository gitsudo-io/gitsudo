defmodule Gitsudo.Repo.Migrations.CreateWorkflowRuns do
  use Ecto.Migration

  def change do
    create table(:workflow_runs, primary_key: false) do
      add :id, :bigint, primary_key: true

      add :workflow_id,
          references(:workflows, type: :integer, on_delete: :delete_all, null: false)

      add :name, :string
      add :run_started_at, :utc_datetime
      add :status, :string
      add :conclusion, :string

      timestamps()
    end

    create index(:workflow_runs, [:workflow_id])
  end
end
