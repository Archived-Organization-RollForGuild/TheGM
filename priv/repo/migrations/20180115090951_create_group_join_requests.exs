defmodule Thegm.Repo.Migrations.CreateGroupJoinRequests do
  use Ecto.Migration

  def change do
    create table(:group_join_requests, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :uuid)
      add :group_id, references(:groups, on_delete: :delete_all, type: :uuid)
      add :approved, :boolean

      timestamps()
    end

    create index(:group_join_requests, [:user_id])
    create index(:group_join_requests, [:group_id])
  end
end
