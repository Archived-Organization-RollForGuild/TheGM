defmodule Thegm.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :street1, :string, null: false
      add :street2, :string
      add :city, :string, null: false
      add :state, :string, null: false
      add :country, :string
      add :zip, :string, null: false
      add :lat, :float, null: false
      add :lon, :float, null: false
      add :email, :string, null: false
      add :phone, :string, null: false
      add :games, {:array, :string}

      timestamps()
    end
  end
end
