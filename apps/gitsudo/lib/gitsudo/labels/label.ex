defmodule Gitsudo.Labels.Label do
  @moduledoc """
  A Label
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "labels" do
    belongs_to :owner, Gitsudo.Accounts.Account
    field(:color, :string)
    field(:name, :string)
    field(:description, :string)

    many_to_many :repositories, Gitsudo.Repositories.Repository,
      join_through: "repositories_labels"

    has_many :collaborator_policies, Gitsudo.Policies.CollaboratorPolicy
    has_many :team_policies, Gitsudo.Policies.TeamPolicy

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
    |> cast(attrs, [:owner_id, :name, :color, :description])
    |> cast_assoc(:team_policies, with: &Gitsudo.Policies.TeamPolicy.changeset/2)
    |> validate_required([:owner_id, :name, :color])
    |> unique_constraint(:name, name: :labels_owner_id_name_index)
  end
end
