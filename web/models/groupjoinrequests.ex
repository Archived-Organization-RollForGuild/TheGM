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

  def create_new_join_request_notifications(groups_id, user) do
    with {:ok, group} <- Thegm.Groups.get_group_by_id!(groups_id),
      {:ok, recipients} <- Thegm.GroupMembers.get_admin_ids(groups_id) do
        type = "group::new-join-request"
        body = "#{user.username} requested to join your group #{group.name}"
        resources = [%{resources_type: "groups", resources_id: groups_id}, %{resources_type: "users", resources_id: user.id}]
        Thegm.Notifications.create_notifications(body, type, recipients, resources)
    end
  end
  
  def create_new_join_request_acceptance_notification(groups_id, users_id) do
    with {:ok, group} <- Thegm.Groups.get_group_by_id!(groups_id) do
        type = "group::join-request-accepted"
        body = "Woohoo! You've been accepted into #{group.name}!"
        resources = [%{resources_type: "groups", resources_id: groups_id}]
        Thegm.Notifications.create_notifications(body, type, [users_id], resources)
    end
  end
end
# credo:disable-for-this-file
