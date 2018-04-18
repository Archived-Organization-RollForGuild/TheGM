defmodule Thegm.Repo.Migrations.CreateEventGames do
  use Ecto.Migration

  def change do
    create table(:event_games, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :groups_id, references(:groups, on_delete: :nothing, type: :uuid)
      add :games_id, references(:games, on_delete: :delete_all, type: :uuid)
      add :game_suggestions_id, references(:game_suggestions, on_delete: :nothing, type: :uuid)
    end

    # Ensures database side that one of games_id or game_suggestions_id is populated,
    # but not both
    create constraint(:event_games, :exactly_one, check: "(games_id IS NOT NULL)::integer + (game_suggestions_id IS NOT NULL)::integer = 1")
  end
end
