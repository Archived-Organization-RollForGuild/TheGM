defmodule Thegm.GroupMembers do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "group_members" do
    field :role, :string
    belongs_to :users, Thegm.Users
    belongs_to :groups, Thegm.Groups

    timestamps()
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:groups_id, :users_id, :role])
  end
end
