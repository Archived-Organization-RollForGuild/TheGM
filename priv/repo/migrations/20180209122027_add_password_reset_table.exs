defmodule Thegm.Repo.Migrations.AddPasswordResetTable do
  use Ecto.Migration

  def change do
    create table(:password_resets, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :uuid)
      add :used, :boolean, default: false
      timestamps()
    end
  end
end
