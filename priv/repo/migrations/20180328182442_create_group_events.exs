defmodule Thegm.Repo.Migrations.CreateGroupEvents do
  use Ecto.Migration

  def change do
    create table(:group_events, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string, size: 8192, null: false
      add :description, :string, size: 8192
      add :games_id, references(:games, on_delete: :nothing, type: :uuid)
      add :groups_id, references(:groups, on_delete: :nothing, type: :uuid)
      add :location, :string, size: 8192
      add :start_time, :utc_datetime, null: false
      add :end_time, :utc_datetime, null: false

      timestamps()
    end
  end
end
