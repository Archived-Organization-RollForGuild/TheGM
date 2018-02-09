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
            Thegm.ConfirmationCodesController.new(resp.id, resp.email)
            Thegm.Mailchimp.subscribe_new_user(resp.email)
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

  def show(conn, %{"user_id" => user_id}) do
    current_user_id = conn.assigns[:current_user].id
    case Repo.get(Users, user_id) |> Repo.preload([{:group_members, :groups}]) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `id` was not found"])
      user ->
      cond do
        current_user_id == user_id ->
          render conn, "private.json", user: user
        true ->
          render conn, "public.json", user: user
      end
    end
  end
end
