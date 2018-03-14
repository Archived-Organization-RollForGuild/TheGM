defmodule Thegm.Repo.Migrations.CreateGroupThreadComments do
  use Ecto.Migration

  def change do
    create table(:group_thread_comments, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :group_threads_id, references(:threads, on_delete: :nothing, type: :uuid)
      add :groups_id, references(:groups, on_delete: :nothing, type: :uuid)
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)
      add :comment, :string, size: 8192, null: false

      timestamps()
    end
  end
end
