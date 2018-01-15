defmodule Thegm.GroupMembers do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id
  
  schema "group_members" do
    field :role, :string
    belongs_to :user, Thegm.Users
    belongs_to :group, Thegm.Groups

    timestamps()
  end
end
