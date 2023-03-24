defmodule Gitsudo.Repo.Migrations.CreateCollaboratorPolicies do
  use Ecto.Migration

  def change do
    create_query = """
      CREATE TYPE collaborator_permission
      AS ENUM ('pull', 'triage', 'push', 'maintain', 'admin')
    """

    drop_query = "DROP TYPE collaborator_permission"

    execute(create_query, drop_query)

    create table(:collaborator_policies) do
      add :label_id, references(:labels, on_delete: :delete_all)
      add :collaborator_id, references(:accounts, on_delete: :nothing)
      add :permission, :collaborator_permission, null: false

      timestamps()
    end

    create index(:collaborator_policies, [:label_id])
  end
end
