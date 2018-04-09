defmodule Thegm.GroupJoinRequests do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "group_join_requests" do
    field :status, :string
    field :pending, :boolean
    belongs_to :users, Thegm.Users
    belongs_to :groups, Thegm.Groups

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:status, :groups_id, :users_id])
    |> validate_required([:users_id, :groups_id])
    |> unique_constraint(:users_id, name: :group_join_requests_user_id_group_id_pending_index)
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:status])
    |> validate_required([:status])
    |> put_change(:pending, nil)
  end
end
# credo:disable-for-this-file
