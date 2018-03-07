defmodule Thegm.SessionsView do
  use Thegm.Web, :view

  def render("show.json", %{session: session}) do
    %{data: session_json(session)}
  end

  def session_json(session) do
    %{type: "sessions", attributes: %{token: session.token, user_id: session.users_id}}
  end
end
