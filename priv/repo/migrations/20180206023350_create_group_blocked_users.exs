defmodule Thegm.Repo.Migrations.CreateGroupBlockedUsers do
  use Ecto.Migration

  def change do
    create table(:group_blocked_users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :uuid)
      add :group_id, references(:groups, on_delete: :delete_all, type: :uuid)
      add :rescinded, :boolean, default: false

      timestamps()
    end

    create index(:group_blocked_users, [:user_id])
    create index(:group_blocked_users, [:group_id])
  end
end
