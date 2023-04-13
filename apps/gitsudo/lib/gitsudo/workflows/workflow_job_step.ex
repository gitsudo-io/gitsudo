defmodule Gitsudo.Workflows.WorkflowJobStep do
  @moduledoc """
  The WorkflowJobStep schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "workflow_job_steps" do
    belongs_to :workflow_job, Gitsudo.Workflows.WorkflowJob

    field :number, :integer
    field :name, :string
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :status, :string
    field :conclusion, :string

    timestamps()
  end

  @doc false
  def changeset(workflow_job_step, attrs) do
    workflow_job_step
    |> cast(attrs, [:number, :name, :started_at, :completed_at, :status, :conclusion])
    |> validate_required([:number, :name, :started_at, :completed_at, :status, :conclusion])
  end
end
