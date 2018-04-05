defmodule Thegm.Repo.Migrations.AlterThreads do
  use Ecto.Migration

  def change do
    alter table(:threads) do
      add :deleted, :boolean, null: false, default: false
    end
  end
end
