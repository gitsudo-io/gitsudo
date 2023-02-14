defmodule Gitsudo.Repositories.Repository do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "repositories" do
    field :name, :string
    field :owner_id, :integer

    timestamps()
  end

  @doc false
  def changeset(repository, attrs) do
    repository
    |> cast(attrs, [:id, :owner_id, :name])
    |> validate_required([:id, :owner_id, :name])
  end
end
