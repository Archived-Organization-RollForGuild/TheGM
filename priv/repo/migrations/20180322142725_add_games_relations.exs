defmodule Thegm.Repo.Migrations.AddGamesRelations do
  use Ecto.Migration

  def change do
    create table(:user_games, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)
      add :games_id, references(:games, on_delete: :delete_all, type: :uuid)

      timestamps()
    end

    create table(:group_games, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :groups_id, references(:groups, on_delete: :nothing, type: :uuid)
      add :games_id, references(:games, on_delete: :delete_all, type: :uuid)

      timestamps()
    end


    create index(:user_games, [:users_id])
    create index(:user_games, [:games_id])

    create index(:group_games, [:groups_id])
    create index(:group_games, [:games_id])
  end
end
