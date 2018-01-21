defmodule Thegm.Repo.Migrations.DropGroupsEmail do
  use Ecto.Migration

  def change do
    alter table("groups") do
      remove :email
    end
  end
end
