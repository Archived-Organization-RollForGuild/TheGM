defmodule Thegm.Repo.Migrations.AddProfileFields do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :avatar, :boolean, null: false, default: false
      add :bio, :string, size: 511
    end

    drop unique_index(:groups, [:name])
    create unique_index(:groups, [:slug])
  end
end
