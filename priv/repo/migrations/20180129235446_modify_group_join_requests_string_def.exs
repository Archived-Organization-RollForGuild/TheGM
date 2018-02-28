defmodule Thegm.Repo.Migrations.ModifyGroupJoinRequestsStringDef do
  use Ecto.Migration

  def change do
    alter table(:group_join_requests) do
      remove :approved
      add :status, :string
    end
  end
end
