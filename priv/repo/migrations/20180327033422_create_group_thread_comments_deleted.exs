defmodule Thegm.Repo.Migrations.CreateGroupThreadCommentsDeleted do
  use Ecto.Migration

  def change do
    alter table(:group_thread_comments) do
      add :deleted, :boolean, null: false, default: false
    end
  end
end
