defmodule Thegm.Repo.Migrations.ChangeExistingAdminsToOwner do
  use Ecto.Migration

  def change do
    execute "UPDATE group_members SET \"role\" = 'owner' WHERE \"role\" = 'admin'"
  end
end
