defmodule Thegm.Repo.Migrations.AlterGroupThreadComments do
  use Ecto.Migration

  def change do
    create table(:group_thread_comments_deleted, primary_key: false) do
      add :group_thread_comments_id, references(:group_thread_comments, on_delete: :nothing, type: :uuid), primary_key: true
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)
      add :deleter_role, :string, null: false

      timestamps()
    end
  end
end
