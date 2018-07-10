defmodule Thegm.NotificationsController do
  use Thegm.Web, :controller

  def index(conn, params) do
    users_id = conn.assigns[:current_user].id
    now = NaiveDateTime.utc_now()
    with {:ok, pagination_params} <- Thegm.Reader.read_pagination_params(params),
      {:ok, total} <- Thegm.Notifications.get_total_for_user_before(users_id, now),
      offset <- (pagination_params.page - 1) * pagination_params.limit,
      {:ok, notifications} <- Thegm.Notifications.get_notifications_for_user_before_with_pagination(users_id, now, pagination_params) do
        Task.start(Thegm.Notifications, :mark_notifications_as_not_new_for_user_before, [users_id, now])
        meta = %{total: total, limit: pagination_params.limit, offset: offset, count: length(notifications)}
        conn
        |> put_status(:ok)
        |> render("index.json", notifications: notifications, meta: meta)
    else
      {:error, :not_found, error} ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: error)
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: error)
    end
  end
end
