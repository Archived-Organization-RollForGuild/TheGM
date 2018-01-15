defmodule Thegm.Repo.Migrations.CreateGroupJoinInvites do
  use Ecto.Migration

  def change do
    create table(:group_join_invites, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :uuid)
      add :group_id, references(:groups, on_delete: :nothing, type: :uuid)
      add :accepted, :boolean

      timestamps()
    end

    create index(:group_join_invites, [:user_id])
    create index(:group_join_invites, [:group_id])
  end
end
