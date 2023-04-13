defmodule Gitsudo.Workflows.WorkflowRun do
  @moduledoc """
  The WorkflowRun schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "workflow_runs" do
    belongs_to :workflow, Gitsudo.Workflows.Workflow

    field :name, :string
    field :run_started_at, :utc_datetime
    field :status, :string
    field :conclusion, :string

    has_many :workflow_jobs, Gitsudo.Workflows.WorkflowJob

    timestamps()
  end

  @doc false
  def changeset(workflow_run, attrs) do
    workflow_run
    |> cast(attrs, [:id, :workflow_id, :name, :run_started_at, :status, :conclusion])
    |> validate_required([:id, :workflow_id, :name, :run_started_at, :status])
  end
end
