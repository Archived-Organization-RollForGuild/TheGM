defmodule Thegm.GroupMembers do
  @moduledoc "Database model for group members"

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
    |> unique_constraint(:groups_id, name: :group_members_groups_id_users_id_index)
    |> foreign_key_constraint(:groups_id, name: :group_members_groups_id_fk)
  end
end
