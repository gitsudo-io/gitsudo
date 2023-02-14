defmodule Gitsudo.Labels.Label do
  @moduledoc """
  A Label
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "labels" do
    field(:color, :string)
    field(:name, :string)

    timestamps()
  end

  @spec changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(label, attrs) do
    label
    |> cast(attrs, [:name, :color])
    |> validate_required([:name, :color])
  end
end
