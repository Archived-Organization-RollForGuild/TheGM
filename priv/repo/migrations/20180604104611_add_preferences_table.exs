defmodule Thegm.Repo.Migrations.AddPreferencesTable do
  use Ecto.Migration

  def change do
    create table(:preferences, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)
      timestamps()
    end

    execute "CREATE EXTENSION \"uuid-ossp\""

    execute "INSERT INTO preferences(id,inserted_at,updated_at, users_id)
    SELECT uuid_generate_v4(), current_timestamp, current_timestamp, users.id
    FROM users"
  end
end
