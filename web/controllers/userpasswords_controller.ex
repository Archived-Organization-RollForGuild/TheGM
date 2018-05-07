defmodule Thegm.UserPasswordsController do
  use Thegm.Web, :controller

  alias Thegm.Users
  alias Thegm.UsersView
  import Comeonin.Argon2, only: [checkpw: 2, dummy_checkpw: 0]


  def update(conn, %{"users_id" => users_id, "data" => %{"attributes" => params, "type" => type}}) do
    current_user_id = conn.assigns[:current_user].id
    cond do
      type == "users" ->
        case Repo.get(Users, users_id) |> Repo.preload([{:group_members, :groups}]) do
          nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `username` was not found"])
          user ->
            cond do
              current_user_id == users_id && checkpw(params["current_password"], user.password_hash) ->
                user = Users.update_password_changeset(user, params)
                case Repo.update(user) do
                  {:ok, result} ->
                    conn
                    |> put_status(:ok)
                    |> render(UsersView, "private.json", user: result)
                  {:error, changeset} ->
                    conn
                    |> put_status(:unprocessable_entity)
                    |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                end
              true ->
                dummy_checkpw()
                conn
                |> put_status(:unauthorized)
                |> render(Thegm.ErrorView, "error.json", errors: ["Invalid password or user"])
            end
        end
      true ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `users` data type"])
    end
  end
end
# credo:disable-for-this-file
