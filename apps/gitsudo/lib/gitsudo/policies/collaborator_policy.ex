defmodule Gitsudo.Policies.CollaboratorPolicy do
  @moduledoc """
  A CollabolatorPolicy defines a policy for adding a GitHub user as a collaborator
  to a repository, with the specified permission level.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "collaborator_policies" do
    belongs_to :label, Gitsudo.Labels.Label
    has_one :owner, through: [:label, :owner]

    belongs_to :collaborator, Gitsudo.Accounts.Account
    field :permission, Ecto.Enum, values: [:pull, :triage, :push, :maintain, :admin]

    timestamps()
  end

  @doc false
  def changeset(collaborator_policy, attrs) do
    collaborator_policy
    |> cast(attrs, [:owner_id, :label_id, :collaborator_id, :permission])
    |> validate_required([])
  end
end
