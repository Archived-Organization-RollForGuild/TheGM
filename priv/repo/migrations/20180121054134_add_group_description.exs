defmodule Thegm.Repo.Migrations.AddGroupDescription do
  use Ecto.Migration

  def change do
    alter table("groups") do
      add :description, :text
    end
  end
end
