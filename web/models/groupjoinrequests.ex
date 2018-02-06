defmodule Thegm.GroupJoinRequests do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "group_join_requests" do
    field :status, :string
    belongs_to :user, Thegm.Users
    belongs_to :group, Thegm.Groups

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:status, :group_id, :user_id])
    |> validate_required([:user_id, :group_id])
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:status])
    |> validate_required([:status])
  end
end
