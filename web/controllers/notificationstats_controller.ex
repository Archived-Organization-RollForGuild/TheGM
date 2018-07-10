defmodule Thegm.NotificationStatsController do
  use Thegm.Web, :controller

  def show(conn, _) do
    users_id = conn.assigns[:current_user].id
    with {:ok, new} <- Thegm.Notifications.how_many_new_notifications_does_user_have(users_id) do
      conn
      |> put_status(:ok)
      |> render("show.json", new: new)
    end
  end
end
