defmodule Thegm.Repo.Migrations.AddGeogToGroups do
  use Ecto.Migration

  def change do
    alter table("groups") do
      add :geog, :geography
      remove :lat
      remove :lon
    end
  end
end
