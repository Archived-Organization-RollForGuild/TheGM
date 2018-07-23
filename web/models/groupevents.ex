defmodule Thegm.GroupEvents do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "group_events" do
    field :title, :string
    field :description, :string
    field :location, :string
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :deleted, :boolean
    belongs_to :groups, Thegm.Groups
    has_many :group_event_games, Thegm.GroupEventGames

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:title, :description, :location, :start_time, :end_time, :groups_id])
    |> validate_required([:title, :start_time, :end_time, :groups_id], message: "are required.")
    |> validate_length(:title, min: 1, max: 8192, message: "must be between 1 and 8192 characters.")
    |> validate_length(:description, max: 8192, message: "must be less than 8192 characters")
    |> validate_length(:location, max: 8192, message: "must be less than 8192 characters")
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:title, :description, :location, :start_time, :end_time])
    |> validate_length(:title, min: 1, max: 8192, message: "must be between 1 and 8192 characters.")
    |> validate_length(:description, max: 8192, message: "must be less than 8192 characters")
    |> validate_length(:location, max: 8192, message: "must be less than 8192 characters")
  end

  def delete_changeset(model) do
    model
    |> cast(%{deleted: true}, [:deleted])
  end

  def create_new_event_notification(event, groups_id, users_id) do
    with {:ok, group} <- Thegm.Groups.get_group_by_id!(groups_id),
      {:ok, recipients} <- Thegm.GroupMembers.get_group_member_ids(groups_id, [users_id]) do
        event_date_string = event.start_time
          |> DateTime.to_date
          |> Date.to_erl
          |> Timex.format!("{Mfull} {D}, {YYYY}")
        type = "group::new-event"
        body = "#{group.name} just set up a new event #{event.title} on #{event_date_string}"
        resources = [%{resources_type: "groups", resources_id: groups_id}, %{resources_type: "events", resources_id: event.id}]
        Thegm.Notifications.create_notifications(body, type, recipients, resources)
    end
  end
end
# credo:disable-for-this-file
