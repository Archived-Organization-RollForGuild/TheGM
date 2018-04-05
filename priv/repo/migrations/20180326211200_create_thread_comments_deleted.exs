defmodule Thegm.Repo.Migrations.CreateThreadCommentsDeleted do
  use Ecto.Migration

  def change do
    create table(:thread_comments_deleted, primary_key: false) do
      add :thread_comments_id, references(:thread_comments, on_delete: :nothing, type: :uuid), primary_key: true
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)
      add :deleter_role, :string, null: false

      timestamps()
    end
  end
end
