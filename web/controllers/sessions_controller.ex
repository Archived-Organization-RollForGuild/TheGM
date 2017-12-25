defmodule Thegm.SessionsController do
  use Thegm.Web, :controller

  alias Thegm.Sessions
  alias Thegm.Users

  import Comeonin.Argon2, only: [checkpw: 2, dummy_checkpw: 0]

  def create(conn, %{"data" => %{"attributes" => params, "type" => type}}) do
    case {type, params} do
      {"auth", user_params} ->
        user = Repo.get_by(Users, email: user_params["email"])
        cond do
          !user.active ->
            conn
            |> put_status(:bad_request)
            |> render(Thegm.ErrorView, "error.json", errors: ["Account has not been verified"])
          user && checkpw(user_params["password"], user.password_hash) ->
            session_changeset = Sessions.create_changeset(%Sessions{}, %{user_id: user.id})
            {:ok, session} = Repo.insert(session_changeset)
            conn
            |> put_status(:created)
            |> render("show.json", session: session)
          user ->
            conn
            |> put_status(:unauthorized)
            |> render(Thegm.ErrorView, "error.json", errors: ["Invalid Email/Password combination"])
          true ->
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

end
