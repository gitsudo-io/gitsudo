defmodule Gitsudo.Repo.Migrations.CreateWorkflowJobSteps do
  use Ecto.Migration

  def change do
    create table(:workflow_job_steps) do
      add :workflow_job_id,
          references(:workflow_jobs, type: :bigint, on_delete: :delete_all, null: false)

      add :number, :integer
      add :name, :string
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :status, :string
      add :conclusion, :string

      timestamps()
    end

    create index(:workflow_job_steps, [:workflow_job_id])
  end
end
