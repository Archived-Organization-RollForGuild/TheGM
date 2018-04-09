defmodule Thegm.GroupMembers do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  @member_roles ["owner", "admin", "member"]
  @admin_roles ["owner", "admin"]

  schema "group_members" do
    field :role, :string
    field :active, :boolean
    belongs_to :users, Thegm.Users
    belongs_to :groups, Thegm.Groups

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:groups_id, :users_id, :role])
    |> validate_required([:groups_id, :users_id, :role], message: "Are required")
    |> unique_constraint(:groups_id, name: :group_members_groups_id_users_id_index)
    |> foreign_key_constraint(:groups_id, name: :group_members_groups_id_fk)
  end

  def role_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:role])
    |> validate_required([:role], message: "Are required")
    |> validate_inclusion(:role, @member_roles)
  end

  def tombstone_changeset(model) do
    model
    |> put_change(:active, nil)
  end

  def isOwner(model) do
    model.role == "owner"
  end

  def isAdmin(model) do
    Enum.any?(@admin_roles, fn role -> model.role == role end)
  end

  def isMember(model) do
    Enum.any?(@member_roles, fn role -> model.role == role end)
  end
end
# credo:disable-for-this-file
