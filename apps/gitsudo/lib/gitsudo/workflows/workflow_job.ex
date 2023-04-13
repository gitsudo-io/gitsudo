defmodule Gitsudo.Workflows.WorkflowJob do
  @moduledoc """
  The WorkflowJob schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "workflow_jobs" do
    belongs_to :workflow_run, Gitsudo.Workflows.WorkflowRun

    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :status, :string
    field :conclusion, :string

    has_many :workflow_job_steps, Gitsudo.Workflows.WorkflowJobStep

    timestamps()
  end

  @doc false
  def changeset(workflow_job, attrs) do
    workflow_job
    |> cast(attrs, [:id, :started_at, :completed_at, :status, :conclusion])
    |> validate_required([:id, :started_at, :completed_at, :status, :conclusion])
  end
end
