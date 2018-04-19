defmodule Thegm.Repo.Migrations.AddMessagesTables do
  @moduledoc "Migration that adds tables to the database for instant messaging"
  use Ecto.Migration

  def change do
    create table(:message_threads, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title_encrypted, :binary, null: true
      add :iv, :string

      timestamps()
    end

    create table(:messages, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :body_encrypted, :binary, null: false
      add :iv, :string, null: false
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)
      add :message_threads_id, references(:message_threads, on_delete: :delete_all, type: :uuid)

      timestamps()
    end

    create table(:message_participants, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :status, :string, null: false, default: "member"
      add :active, :boolean, null: false, default: true
      add :silenced, :boolean, null: false, default: false
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)
      add :message_threads_id, references(:message_threads, on_delete: :delete_all, type: :uuid)

      timestamps()
    end

    create index(:message_participants, [:users_id])
    create index(:message_participants, [:message_threads_id])
  end
end
