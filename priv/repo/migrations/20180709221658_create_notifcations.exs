defmodule Thegm.Repo.Migrations.CreateNotifcations do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :body, :string, size: 8192, null: false
      add :type, :string, size: 100, null: false
      add :new, :boolean, null: false, default: true
      add :clicked, :boolean, null: false, default: false
      add :notify_at, :utc_datetime, null: false, default: fragment("NOW()")
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)

      timestamps()
    end
  end
end
