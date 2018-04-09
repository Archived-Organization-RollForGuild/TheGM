defmodule Thegm.SessionsController do
  use Thegm.Web, :controller

  alias Thegm.Sessions
  alias Thegm.Users

  import Comeonin.Argon2, only: [checkpw: 2, dummy_checkpw: 0]

  def show(conn, %{"id" => token}) do
    session = Repo.one(from s in Sessions, where: s.token == ^token)
    cond do
      session ->
        conn
        |> render("show.json", session: session)

      true ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Unable to locate session"])
    end
  end

  def create(conn, %{"data" => %{"attributes" => params, "type" => type}}) do
    case {type, params} do
      {"auth", user_params} ->
        user = Repo.get_by(Users, email: user_params["email"])
        cond do
          !user ->
            dummy_checkpw()
            conn
            |> put_status(:unauthorized)
            |> render(Thegm.ErrorView, "error.json", errors: ["Invalid Email/Password combination"])

          !user.active ->
            conn
            |> put_status(:bad_request)
            |> render(Thegm.ErrorView, "error.json", errors: ["Account has not been verified"])
          user && checkpw(user_params["password"], user.password_hash) ->
            session_changeset = Sessions.create_changeset(%Sessions{}, %{users_id: user.id})
            {:ok, session} = Repo.insert(session_changeset)
            conn
            |> put_status(:created)
            |> render("show.json", session: session)
          user || true ->
            dummy_checkpw()
            conn
            |> put_status(:unauthorized)
            |> render(Thegm.ErrorView, "error.json", errors: ["Invalid Email/Password combination"])
        end
      _ ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `auth` data type"])
    end
  end

  def delete(conn, _params) do
    auth = get_req_header(conn, "authorization")
    {:ok, token} = Thegm.AuthenticateUser.parse_token(auth)

    session = Repo.one(from s in Sessions, where: s.token == ^token)
    Repo.delete session
    conn
    |> send_resp(:ok, "")
  end
end
# credo:disable-for-this-file
