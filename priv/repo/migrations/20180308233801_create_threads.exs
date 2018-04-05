defmodule Thegm.Repo.Migrations.CreateCommunityThreads do
  use Ecto.Migration

  def change do
    create table(:threads, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :body, :string, size: 8192, null: false
      add :title, :string, size: 256, null: false
      add :pinned, :boolean, default: false
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)

      timestamps()
    end

  end
end
