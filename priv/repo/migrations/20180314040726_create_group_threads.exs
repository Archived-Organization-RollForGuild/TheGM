defmodule Thegm.Repo.Migrations.CreateGroupThreads do
  use Ecto.Migration

  def change do
    create table(:group_threads, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :body, :string, size: 8192, null: false
      add :title, :string, size: 256, null: false
      add :pinned, :boolean, default: false
      add :groups_id, references(:groups, on_delete: :nothing, type: :uuid)
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)

      timestamps()
    end
  end
end
