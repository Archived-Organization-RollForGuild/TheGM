defmodule Thegm.Repo.Migrations.SessionsUuidPrimaryKey do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      remove :id
      modify :token, :string, primary_key: true
    end
  end
end
