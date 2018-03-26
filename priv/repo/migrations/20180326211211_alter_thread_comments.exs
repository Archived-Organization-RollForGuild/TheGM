defmodule Thegm.Repo.Migrations.AlterThreadComments do
  use Ecto.Migration

  def change do
    alter table(:thread_comments) do
      add :deleted, :boolean, null: false, default: false
    end
  end
end
