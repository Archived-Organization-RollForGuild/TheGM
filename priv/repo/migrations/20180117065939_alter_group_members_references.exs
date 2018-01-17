defmodule Thegm.Repo.Migrations.AlterGroupMembersReferences do
  use Ecto.Migration

  def change do
    rename table("group_members"), :user_id, to: :users_id
    rename table("group_members"), :group_id, to: :groups_id
  end
end
