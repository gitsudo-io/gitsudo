defmodule Gitsudo.Accounts.Account do
  @moduledoc """
  A GitHub Account (user or organization)
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "accounts" do
    field :login, :string
    field :type, :string
    field :avatar_url, :string

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
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:id, :login, :type, :avatar_url])
    |> validate_required([:id, :login, :type])
  end
end
