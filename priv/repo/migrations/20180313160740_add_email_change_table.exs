defmodule Thegm.Repo.Migrations.AddEmailChangeTable do
  use Ecto.Migration

  def change do
    create table(:email_change_codes, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :users_id, references(:users, on_delete: :nothing, type: :uuid)
      add :used, :boolean, default: false
      add :email, :string
      add :old_email, :string
      timestamps()
    end
  end
end
