defmodule Thegm.Repo.Migrations.GroupGamesAddSuggestionReferences do
  use Ecto.Migration

  def change do
    alter table(:group_games) do
      add :game_suggestions_id, references(:game_suggestions, on_delete: :nothing, type: :uuid)
    end

    # Ensures database side that one of games_id or game_suggestions_id is populated,
    # but not both
    create constraint(:group_games, :exactly_one, check: "(games_id IS NOT NULL)::integer + (game_suggestions_id IS NOT NULL)::integer = 1")
    create unique_index(:group_games, [:games_id, :groups_id])
    create unique_index(:group_games, [:game_suggestions_id, :groups_id])
  end
end
