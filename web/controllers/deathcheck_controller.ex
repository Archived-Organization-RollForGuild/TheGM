defmodule Thegm.DeathCheckController do
  @moduledoc "Controller responsible for handling death checks"
  use Thegm.Web, :controller

  def index(conn, _) do
    conn |> put_status(:ok) |> render(Thegm.DataMessagesView, "message.json", %{message: "Successful saving throw!"})
  end
end
