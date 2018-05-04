defmodule Thegm.Repo.Migrations.AlterGameSuggestionsAddGroupsId do
  use Ecto.Migration

  def change do
    # Allow for a suggestion to be tied to a group
    alter table(:game_suggestions) do
      add :groups_id, references(:groups, on_delete: :nothing, type: :uuid)
    end
  end
end
