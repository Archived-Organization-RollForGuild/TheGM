defmodule Thegm.Repo.Migrations.AddPreferencesTimezone do
  use Ecto.Migration

  def change do
    alter table(:preferences) do
      add :timezone, :integer, null: true
    end
  end
end
