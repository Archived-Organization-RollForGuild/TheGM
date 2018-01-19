defmodule Thegm.Repo.Migrations.CascadeGroupDeletion do
  use Ecto.Migration

  def change do
    alter table(:group_members) do
      modify :groups_id, references(:groups, on_delete: :delete_all, type: :uuid), null: false
      execute "ALTER TABLE group_members DROP CONSTRAINT group_members_group_id_fk"
    end
  end
end
