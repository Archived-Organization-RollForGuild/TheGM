defmodule Thegm.Repo.Migrations.AddPreferencesMeasurement do
  use Ecto.Migration

  def change do
    alter table(:preferences) do
      add :units, :string, null: true
    end
  end
end
