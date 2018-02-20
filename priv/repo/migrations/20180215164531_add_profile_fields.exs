defmodule Thegm.Repo.Migrations.AddProfileFields do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :avatar, :boolean, null: false, default: false
      add :bio, :string, size: 511
    end
  end
end
