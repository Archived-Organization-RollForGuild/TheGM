defmodule Thegm.Repo.Migrations.CreateThreadsDeleted do
  use Ecto.Migration

  def change do
    create table(:threads_deleted, primary_key: false) do
      add :threads_id, references(:threads, on_delete: :nothing, type: :uuid), primary_key: true
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)
      add :deleter_role, :string, null: false

      timestamps()
    end
  end
end
