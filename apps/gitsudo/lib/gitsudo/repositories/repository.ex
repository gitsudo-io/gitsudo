defmodule Gitsudo.Repositories.Repository do
  @moduledoc """
  A GitHub Repository
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "repositories" do
    belongs_to :owner, Gitsudo.Accounts.Account
    field :name, :string

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
  def changeset(repository, attrs) do
    repository
    |> cast(attrs, [:id, :owner_id, :name])
    |> validate_required([:id, :owner_id, :name])
  end
end
