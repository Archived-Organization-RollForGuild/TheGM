defmodule Thegm.Repo.Migrations.DropFieldFromUserGames do
  use Ecto.Migration

  def change do
    alter table(:user_games) do
      remove :field
    end
  end
end
