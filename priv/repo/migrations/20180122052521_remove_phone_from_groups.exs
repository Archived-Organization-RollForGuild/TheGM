defmodule Thegm.Repo.Migrations.RemovePhoneFromGroups do
  use Ecto.Migration

  def change do
    alter table("groups") do
      remove :phone
    end
  end
end
