defmodule Thegm.Repo.Migrations.CreateDeletedThreads do
  use Ecto.Migration

  def change do
    create table(:deleted_threads, primary_key: false) do
      add :groups_id, references(:threads, on_delete: :nothing, type: :uuid), primary_key: true
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)
      add :deleter_role, :string, null: false

      timestamps()
    end
  end
end
