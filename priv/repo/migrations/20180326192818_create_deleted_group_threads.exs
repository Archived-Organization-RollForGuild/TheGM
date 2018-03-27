defmodule Thegm.Repo.Migrations.CreateDeletedGroupThreads do
  use Ecto.Migration

  def change do
    create table(:group_threads_deleted, primary_key: false) do
      add :group_threads_id, references(:group_threads, on_delete: :nothing, type: :uuid), primary_key: true
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)
      add :deleter_role, :string, null: false

      timestamps()
    end
  end
end
