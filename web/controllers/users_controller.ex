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
            spawn Thegm.ConfirmationCodesController.new(resp.id, resp.email)
            spawn Thegm.Mailchimp.subscribe_new_user(resp.email)
            send_resp(conn, :created, "")
          {:error, resp} ->
            error_list = Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end)
            conn
            |> put_status(:bad_request)
            |> render(Thegm.ErrorView, "error.json", errors: error_list)
        end
      _ ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `user` data type"])
    end
  end
end
