defmodule Thegm.NotificationResources do
  use Thegm.Web, :model

  @primary_key false
  @foreign_key_type :binary_id

  schema "notification_resources" do
    field :resources_type, :string
    field :resources_id, :binary_id

    belongs_to :notifications, Thegm.Notifications

    timestamps()
  end

  def changeset(model, params \\ []) do
    model
    |> cast(params, [:resource_type, :resource_id, :notifications_id])
    |> validate_required([:resource_type, :resource_id, :notifications_id])
    |> foreign_key_constraint(:notifications_id, name: :notification_resources_notifications_id_fk)
  end

  def create_changeset(model, params \\ []) do
    changeset(model, params)
  end
end
