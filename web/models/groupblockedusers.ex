defmodule Thegm.GroupBlockedUsers do
  use Thegm.Web, :model
  alias Thegm.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "group_blocked_users" do
    field :rescinded, :boolean
    belongs_to :users, Thegm.Users
    belongs_to :groups, Thegm.Groups
  end

  def get_group_ids_blocking_user(users_id) do
    if is_nil(users_id) do
      {:ok, []}
    else
      blocked_by = Repo.all(from b in Thegm.GroupBlockedUsers, where: b.users_id == ^users_id and b.rescinded == false, select: b.groups_id)
      {:ok, blocked_by}
    end
  end
end
