defmodule Thegm.GroupBlockedUsers do
  @moduledoc "Database model for lists of users that have been blocked from a group"

  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "group_blocked_users" do
    field :rescinded, :boolean
    belongs_to :user, Thegm.Users
    belongs_to :group, Thegm.Groups
  end
end
