defmodule Thegm.Repo.Migrations.RemoveGroupsGamesarray do
  use Ecto.Migration

  def change do
    alter table("groups") do
      remove :games
    end
  end
end
