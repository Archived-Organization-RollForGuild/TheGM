defmodule Thegm.Repo.Migrations.CreateGroupMembers do
  use Ecto.Migration

  def change do
    create table(:group_members, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :uuid)
      add :group_id, references(:groups, on_delete: :nothing, type: :uuid)

      timestamps()
    end

    create index(:group_members, [:user_id])
    create index(:group_members, [:group_id])
  end
end
