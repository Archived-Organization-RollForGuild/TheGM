defmodule Thegm.Repo.Migrations.CreateGroupMembers do
  use Ecto.Migration

  def change do
    create table(:group_members, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)
      add :groups_id, references(:groups, on_delete: :delete_all, type: :uuid)

      timestamps()
    end

    create index(:group_members, [:users_id])
    create index(:group_members, [:groups_id])
  end
end
