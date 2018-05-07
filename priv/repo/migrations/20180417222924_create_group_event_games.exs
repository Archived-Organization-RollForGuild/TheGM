defmodule Thegm.Repo.Migrations.CreateEventGames do
  use Ecto.Migration

  def change do
    create table(:group_event_games, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :group_events_id, references(:group_events, on_delete: :nothing, type: :uuid)
      add :games_id, references(:games, on_delete: :delete_all, type: :uuid)
      add :game_suggestions_id, references(:game_suggestions, on_delete: :nothing, type: :uuid)

      timestamps()
    end

    # Ensures database side that one of games_id or game_suggestions_id is populated,
    # but not both
    create constraint(:group_event_games, :exactly_one, check: "(games_id IS NOT NULL)::integer + (game_suggestions_id IS NOT NULL)::integer = 1")
    create unique_index(:group_event_games, [:games_id, :group_events_id])
    create unique_index(:group_event_games, [:game_suggestions_id, :group_events_id])
  end
end
