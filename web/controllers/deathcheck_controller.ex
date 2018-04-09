defmodule Thegm.DeathCheckController do
  use Thegm.Web, :controller

  def index(conn, _) do
    conn |> put_status(:ok) |> render(Thegm.DataMessagesView, "message.json", %{message: "Successful saving throw!"})
  end
end
# credo:disable-for-this-file
