defmodule Thegm.UsersController do
  use Thegm.Web, :controller

  alias Thegm.Users

  def index(conn, _params) do
    users = Repo.all(Users)
    render conn, "index.json", users: users
  end

  def create(conn, %{"data" => %{"attributes" => params, "type" => type}}) do
    case {type, params} do
      {"users", params} ->
        changeset = Users.changeset(%Users{}, params)

        case Repo.insert(changeset) do
          {:ok, _resp} ->
            send_resp(conn, :created, "")
        end
      _ ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "400.json", errors: ["Posted a non `users` data type"])
    end
  end
end
