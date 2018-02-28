defmodule Thegm.Repo.Migrations.GeogToGeom do
  use Ecto.Migration

  def change do
    alter table("groups") do
      add :geom, :geometry
      remove :geog
    end
  end
end
