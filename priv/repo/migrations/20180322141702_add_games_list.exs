defmodule Thegm.Repo.Migrations.AddGamesList do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :url, :string, null: true
      add :publisher, :string, size: 1023, null: true
      add :description, :string, size: 8192, null: true
      add :version, :string, null: true
      add :avatar, :boolean, null: false, default: false
      add :disambiguations, {:array, :string}, null: false, default: []

      timestamps()
    end
  end
end
