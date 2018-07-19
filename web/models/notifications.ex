defmodule Thegm.Notifications do
  use Thegm.Web, :model
  alias Thegm.Repo
  alias Ecto.Multi

  @moduledoc false

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "notifications" do
    field :body, :string
    field :type, :string
    field :new, :boolean
    field :clicked, :boolean
    field :notify_at, :utc_datetime

    belongs_to :users, Thegm.Users
    has_many :notification_resources, Thegm.NotificationResources

    timestamps()
  end

  def changeset(model, params) do
    model
    |> cast(params, [:body, :type, :new, :clicked, :notify_at, :users_id])
    |> validate_required([:body, :type, :users_id])
    |> foreign_key_constraint(:users_id, name: :notifications_users_id_fk)
  end

  def create_changeset(model, params) do
    changeset(model, params)
  end

  def how_many_new_notifications_does_user_have(users_id) do
    new = Repo.one(from n in Thegm.Notifications,
      select: count(n.id),
      where: n.users_id == ^users_id and n.new == true and n.notify_at <= fragment("NOW()")
      )
    {:ok, new}
  end

  def get_total_for_user_before(users_id, before) do
    total = Repo.one(from n in Thegm.Notifications,
      select: count(n.id),
      where: n.users_id == ^users_id and n.notify_at <= ^before)
    {:ok, total}
  end

  def get_notifications_for_user_before_with_pagination(users_id, before, pagination) do
    notifications = Repo.all(
      from n in Thegm.Notifications,
      where: n.users_id == ^users_id and n.notify_at <= ^before,
      order_by: [desc: n.notify_at],
      limit: ^pagination.limit,
      offset: ^pagination.offset,
      preload: [:notification_resources]
    )
    {:ok, notifications}
  end

  def mark_notifications_as_not_new_for_user_before(users_id, before) do
    from(n in Thegm.Notifications, where: n.users_id == ^users_id and n.notify_at <= ^before)
    |> Repo.update_all(set: [new: false])
  end

  def create_notifications(body, type, recipients, resources, notify_at \\ DateTime.utc_now) when is_bitstring(body) and is_bitstring(type) and is_list(recipients) and is_list(resources) do
    Enum.each(recipients, fn (recipient) -> insert_notification(body, type, recipient, resources, notify_at) end)
  end

  defp insert_notification(body, type, users_id, [], notify_at) do
    notification_changeset = create_changeset(%Thegm.Notifications{}, %{"body" => body, "type" => type, "notify_at" => notify_at, "users_id" => users_id})
    Repo.insert(notification_changeset)
  end

  defp insert_notification(body, type, users_id, resources, notify_at) do
    notification_changeset = create_changeset(%Thegm.Notifications{}, %{"body" => body, "type" => type, "notify_at" => notify_at, "users_id" => users_id})

    multi = Multi.new
      |> Multi.insert(:notifications, notification_changeset)
      |> Multi.run(:notification_resources, fn %{notifications: notification} ->
        temp = %{notifications_id: notification.id, inserted_at: NaiveDateTime.utc_now, updated_at: NaiveDateTime.utc_now}
        resources = Enum.reduce(resources, [], fn (resource, acc) -> [Map.merge(resource, temp) | acc] end)
        {_, objects} = Repo.insert_all(Thegm.NotificationResources, resources, returning: true)
        {:ok, objects}
      end)

    Repo.transaction(multi)
  end
end
