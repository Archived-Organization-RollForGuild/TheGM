defmodule Thegm.Repo.Migrations.Sessions do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add :token, :string
      add :user_id, references(:users, on_delete: :nothing, type: :uuid)

      timestamps()
    end

    create index(:sessions, [:user_id])
    create index(:sessions, [:token])
  end
end
