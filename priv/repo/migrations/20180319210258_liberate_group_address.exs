defmodule Thegm.Repo.Migrations.LiberateGroupAddress do
  use Ecto.Migration

  def change do
    alter table("groups") do
      modify :address, :string, null: true
    end
  end
end
