defmodule Thegm.Repo.Migrations.AddGroupthreadcommentsSoftdelete do
  use Ecto.Migration

  def change do
    alter table("group_thread_comments") do
      add :deleted_at, :naive_datetime, null: true
    end
  end
end
