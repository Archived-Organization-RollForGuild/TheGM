defmodule Thegm.Repo.Migrations.AlterGroupJoinRequestsAddPending do
  use Ecto.Migration

  def change do
    alter table("group_join_requests") do
      add :pending, :boolean, default: true
    end

    create unique_index(:group_join_requests, [:user_id, :group_id, :pending])
  end
end
