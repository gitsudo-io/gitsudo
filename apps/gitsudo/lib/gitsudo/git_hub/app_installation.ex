defmodule Gitsudo.GitHub.AppInstallation do
  @moduledoc """
  The GitHub app installation Ecto model
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "app_installations" do
    field :access_tokens_url, :string
    belongs_to :account, Gitsudo.Accounts.Account

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
  def changeset(app_installation, attrs) do
    app_installation
    |> cast(attrs, [:id, :account_id, :access_tokens_url])
    |> validate_required([:id, :account_id, :access_tokens_url])
  end
end
