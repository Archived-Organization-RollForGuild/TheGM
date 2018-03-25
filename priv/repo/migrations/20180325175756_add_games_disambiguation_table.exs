defmodule Thegm.Repo.Migrations.AddGamesDisambiguationTable do
  use Ecto.Migration

  def change do
    create table(:games_disambiguations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :games_id, references(:games, on_delete: :delete_all, type: :uuid)

      timestamps()
    end
  end
end
