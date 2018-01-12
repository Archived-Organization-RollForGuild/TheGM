defmodule Thegm.UsersController do
  use Thegm.Web, :controller

  alias Thegm.Users

  def index(conn, _params) do
    users = Repo.all(Users)
    render conn, "index.json", users: users
  end

  def create(conn, %{"data" => %{"attributes" => params, "type" => type}}) do
    case {type, params} do
      {"user", params} ->
        changeset = Users.create_changeset(%Users{}, params)

        case Repo.insert(changeset) do
          {:ok, resp} ->
            Thegm.ConfirmationCodesController.create(resp.id, resp.email)
            send_resp(conn, :created, "")
        end
      _ ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `users` data type"])
    end
  end
end
