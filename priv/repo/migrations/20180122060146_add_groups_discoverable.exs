defmodule Thegm.Repo.Migrations.AddGroupsDiscoverable do
  use Ecto.Migration

  def change do
    alter table("groups") do
      add :discoverable, :boolean, null: false, default: true
    end
  end
end
