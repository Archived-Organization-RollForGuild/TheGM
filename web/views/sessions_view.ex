defmodule Thegm.SessionsView do
  use Thegm.Web, :view

  def render("show.json", %{session: session}) do
    %{data: session_json(session)}
  end

  def session_json(session) do
    %{type: "session", attributes: %{token: session.token, user_id: session.user_id}}
  end
end
