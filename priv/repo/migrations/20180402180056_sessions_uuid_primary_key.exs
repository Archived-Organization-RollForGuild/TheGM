defmodule Thegm.Repo.Migrations.SessionsUuidPrimaryKey do
  use Ecto.Migration

  def change do
    execute "TRUNCATE sessions"

    alter table(:sessions) do
      remove :id
      add :id, :uuid, primary_key: true
    end
  end
end
