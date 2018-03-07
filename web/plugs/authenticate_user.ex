defmodule Thegm.AuthenticateUser do
  import Plug.Conn
  alias Thegm.{Repo, Users, Sessions}
  import Ecto.Query, only: [from: 2]

  def init(options), do: options

  def call(conn, _opts) do
    case find_user(conn) do
      {:ok, user} -> assign(conn, :current_user, user)
      _otherwise -> auth_error!(conn)
    end
  end

  def find_user(conn) do
    with auth_header = get_req_header(conn, "authorization"),
      {:ok, token} <- parse_token(auth_header),
      {:ok, session} <- find_session_by_token(token),
    do: find_user_by_session(session)
  end

  def parse_token(["Bearer " <> token]) do
    {:ok, token}
  end

  def parse_token(_no_token_provided), do: :error

  defp find_session_by_token(token) do
    case Repo.one(from s in Sessions, where: s.token == ^token) do
      nil -> :error
      session -> {:ok, session}
    end
  end

  defp find_user_by_session(session) do
    case Repo.get(Users, session.users_id) do
      nil -> :error
      user -> {:ok, user}
    end
  end

  defp auth_error!(conn) do
    conn
    |> put_status(:unauthorized)
    |> put_resp_header("WWW-Authenticate", "Bearer bearer=<bearer>")
    |> Phoenix.Controller.render(Thegm.ErrorView, "error.json", errors: ["Unauthorized request, please login"])
    |> halt()
  end
end
