defmodule Thegm.Repo.Migrations.AddPreferencesTime do
  use Ecto.Migration

  def change do
    alter table(:preferences) do
      add :time, :string, null: true
    end
  end
end
