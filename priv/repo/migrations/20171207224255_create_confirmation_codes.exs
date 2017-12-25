defmodule Thegm.Repo.Migrations.CreateConfirmationCodes do
  use Ecto.Migration

  def change do
    create table(:confirmation_codes) do
      add :user_id, references(:users, on_delete: :nothing, type: :uuid)
      add :used, :boolean, default: false

      timestamps()
    end
  end
end
