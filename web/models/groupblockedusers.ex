defmodule Thegm.GroupBlockedUsers do
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
