defmodule Thegm.Repo.Migrations.AddThreadcommentsSoftdelete do
  use Ecto.Migration

  def change do
    alter table("thread_comments") do
      add :deleted_at, :naive_datetime, null: true
    end
  end
end
