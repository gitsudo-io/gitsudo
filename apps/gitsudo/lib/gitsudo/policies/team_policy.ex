defmodule Gitsudo.Policies.TeamPolicy do
  @moduledoc """
  A TeamPolicy defines a policy for adding an organization team as a collaborator
  to a repository, with the specified permission level.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "team_policies" do
    belongs_to :label, Gitsudo.Labels.Label
    has_one :owner, through: [:label, :owner]

    field :team_slug, :string
    field :permission, Ecto.Enum, values: [:pull, :triage, :push, :maintain, :admin]

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
  def changeset(team_policy, attrs) do
    team_policy
    |> cast(attrs, [:label_id, :team_slug, :permission])
    |> validate_required([])
  end
end
