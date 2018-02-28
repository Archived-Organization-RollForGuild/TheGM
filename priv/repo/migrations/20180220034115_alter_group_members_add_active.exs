defmodule Thegm.Repo.Migrations.AlterGroupMembersAddActive do
  use Ecto.Migration

  def change do
    alter table("group_members") do
      add :active, :boolean, default: true
    end

    drop index(:group_members, [:groups_id, :users_id])
    create unique_index(:group_members, [:groups_id, :users_id, :active])
  end
end
