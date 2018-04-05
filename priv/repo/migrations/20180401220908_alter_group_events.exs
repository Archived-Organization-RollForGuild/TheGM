defmodule Thegm.Repo.Migrations.AlterGroupEvents do
  use Ecto.Migration

  def change do
    alter table(:group_events) do
      add :deleted, :boolean, null: false, default: false
    end
  end
end
