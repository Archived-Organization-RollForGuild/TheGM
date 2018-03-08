defmodule Thegm.Repo.Migrations.AlterSingularToPlurals do
  use Ecto.Migration

  def change do
    rename table(:group_join_requests), :user_id, to: :users_id
    rename table(:group_join_requests), :group_id, to: :groups_id
    rename table(:group_join_invites), :user_id, to: :users_id
    rename table(:group_join_invites), :group_id, to: :groups_id
    rename table(:group_blocked_users), :user_id, to: :users_id
    rename table(:group_blocked_users), :group_id, to: :groups_id
    rename table(:confirmation_codes), :user_id, to: :users_id
    rename table(:sessions), :user_id, to: :users_id
    rename table(:password_resets), :user_id, to: :users_id
  end
end
