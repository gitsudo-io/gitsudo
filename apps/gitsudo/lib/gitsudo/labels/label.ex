defmodule Gitsudo.Labels.Label do
  use Ecto.Schema
  import Ecto.Changeset

  schema "labels" do
    field :color, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(label, attrs) do
    label
    |> cast(attrs, [:name, :color])
    |> validate_required([:name, :color])
  end
end
