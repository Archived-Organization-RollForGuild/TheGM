defmodule Thegm.Repo.Migrations.AlterGroupMembersAddRole do
  use Ecto.Migration

  def change do
    alter table("group_members") do
      add :role, :string, null: false
    end
  end
end
