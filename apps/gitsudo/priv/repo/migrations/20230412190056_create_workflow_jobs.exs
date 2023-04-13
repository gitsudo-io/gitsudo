defmodule Gitsudo.Repo.Migrations.CreateWorkflowJobs do
  use Ecto.Migration

  def change do
    create table(:workflow_jobs, primary_key: false) do
      add :id, :bigint, primary_key: true

      add :workflow_run_id, references(:workflow_runs, on_delete: :delete_all, null: false)

      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :status, :string
      add :conclusion, :string

      timestamps()
    end

    create index(:workflow_jobs, [:workflow_run_id])
  end
end
