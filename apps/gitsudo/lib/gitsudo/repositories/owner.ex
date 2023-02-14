defmodule Gitsudo.Repositories.Owner do
  @moduledoc """
  A GitHub Repository Owner (user or organization)
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "repository_owners" do
    field :login, :string
    field :type, :string

    timestamps()
  end

  @doc false
  @spec changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  def changeset(owner, attrs) do
    owner
    |> cast(attrs, [:id, :login, :type])
    |> validate_required([:id, :login, :type])
  end
end
