defmodule Gitsudo.Workflows.Workflow do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "workflows" do
    belongs_to :repository, Gitsudo.Repositories.Repository

    field :name, :string
    field :path, :string

    timestamps()
  end

  @doc false
  def changeset(workflow, attrs) do
    workflow
    |> cast(attrs, [:id, :repository_id, :name, :path])
    |> validate_required([:id, :repository_id, :name, :path])
  end
end
