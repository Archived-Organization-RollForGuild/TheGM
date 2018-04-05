defmodule Thegm.Repo.Migrations.CreateThreadComments do
  use Ecto.Migration

  def change do
    create table(:thread_comments, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :threads_id, references(:threads, on_delete: :nothing, type: :uuid)
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)
      add :comment, :string, size: 8192, null: false

      timestamps()
    end
  end
end
