defmodule Thegm.Repo.Migrations.CreateGameSuggestions do
  use Ecto.Migration

  def change do
    create table(:game_suggestions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, size: 8192, null: false
      add :version, :string, size: 8192
      add :publisher, :string, size: 8192
      add :url, :string, size: 8192
      add :status, :string, size: 8192
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)

      timestamps()
    end
  end
end
