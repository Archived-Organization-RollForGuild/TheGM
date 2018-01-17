defmodule Thegm.Repo.Migrations.UniqueGroupsAndGroupMembers do
  use Ecto.Migration

  def change do
    create unique_index(:groups, [:name])
    create unique_index(:group_members, [:groups_id, :users_id])
  end
end
