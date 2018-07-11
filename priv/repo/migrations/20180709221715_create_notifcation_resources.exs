defmodule Thegm.Repo.Migrations.CreateNotifcationResources do
  use Ecto.Migration

  def change do
    create table(:notification_resources, primary_key: false) do
      add :resources_type, :string, size: 100, null: false
      add :resources_id, :uuid, null: false
      add :notifications_id, :uuid, null: false

      timestamps()
    end

    create index(:notification_resources, [:notifications_id])
  end
end
