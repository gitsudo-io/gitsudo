defmodule Gitsudo.Repo.Migrations.CreateTeamPolicies do
  use Ecto.Migration

  def change do
    create_query = """
      CREATE TYPE team_permission
      AS ENUM ('pull', 'triage', 'push', 'maintain', 'admin')
    """

    drop_query = "DROP TYPE team_permission"
    execute(create_query, drop_query)

    create table(:team_policies) do
      add :label_id, references(:labels, on_delete: :delete_all, null: false)
      add :team_slug, :string, null: false
      add :permission, :team_permission, null: false

      timestamps()
    end

    create index(:team_policies, [:label_id])
    create unique_index(:team_policies, [:label_id, :team_slug])
  end
end
