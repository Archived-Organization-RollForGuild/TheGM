defmodule Thegm.Repo.Migrations.ModifyGroupsConcatAddress do
  use Ecto.Migration

  def change do
    alter table("groups") do
      add :address, :string
    end

    flush()

    execute "UPDATE groups SET address = CONCAT(street1,', ', city, ', ', state, ', ', country, ', ', zip)"

    alter table("groups") do
      modify :address, :string, null: false
      remove :street1
      remove :street2
      remove :city
      remove :state
      remove :country
      remove :zip
    end
  end
end
