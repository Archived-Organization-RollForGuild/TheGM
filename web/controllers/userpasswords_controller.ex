defmodule Thegm.UserPasswordsController do
  @moduledoc "Controller responsible for handling changing user passwords"

  use Thegm.Web, :controller

  alias Thegm.Users
  alias Thegm.UsersView
  import Comeonin.Argon2, only: [checkpw: 2, dummy_checkpw: 0]


  def update(conn, %{"users_id" => user_id, "data" => %{"attributes" => params, "type" => type}}) do
    current_user_id = conn.assigns[:current_user].id

    case Repo.get(Users, user_id) |> Repo.preload([{:group_members, :groups}]) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `username` was not found"])
      user ->
        if current_user_id == user_id && checkpw(params["current_password"], user.password_hash) do
          user = Users.update_password(user, params)
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
        else
          dummy_checkpw()
          conn
          |> put_status(:unauthorized)
          |> render(Thegm.ErrorView, "error.json", errors: ["Invalid password or user"])
      end
    end
  end
end
