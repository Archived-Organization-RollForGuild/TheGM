defmodule Thegm.Repo.Migrations.AddGroupsSlug do
  use Ecto.Migration

  def change do
    alter table("groups") do
      add :slug, :string, null: false
    end

    drop unique_index(:groups, [:slug])
    create unique_index(:groups, [:slug])
  end
end
