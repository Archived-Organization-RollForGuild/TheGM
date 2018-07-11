defmodule Thegm.NotificationsView do
  use Thegm.Web, :view

  def render("index.json", %{notifications: notifications, meta: meta}) do
    %{
      meta: Thegm.MetaView.meta(meta),
      data: Enum.map(notifications, fn n -> show_notification(n) end)
    }
  end

  def show_notification(notification) do
    %{
      type: "notifications",
      id: notification.id,
      attributes: %{
        body: notification.body,
        type: notification.type,
        new: notification.new,
        clicked: notification.clicked,
        notify_at: notification.notify_at,
        resources: Enum.map(notification.notification_resources, fn nr -> notification_resource(nr) end)
      }
    }
  end

  def notification_resource(resource) do
    %{
      type: resource.resources_type,
      id: resource.resources_id
    }
  end
end
