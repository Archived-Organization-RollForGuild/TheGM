defmodule Thegm.Repo.Migrations.AddPreferencesDate do
  use Ecto.Migration

  def change do
    alter table(:preferences) do
      add :date, :string, null: true
    end
  end
end
