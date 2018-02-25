defmodule Thegm.UserAvatarsController do
  @moduledoc "Controller responsible for handling user avatars"

  @uuid_namespace UUID.uuid5(:url, "https://rollforguild.com/users/avatar")
  use Thegm.Web, :controller

  alias Thegm.Users
  alias Thegm.AWS

  import Mogrify

  def create(conn, %{"users_id" => user_id, "file" => image_params}) do
    current_user_id = conn.assigns[:current_user].id

    case Repo.get(Users, user_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `id` was not found"])
      user ->
        cond do
          current_user_id == user_id ->
            image_params.path
            |> open
            |> resize("512x512")
            |> format("jpg")
            |> save(in_place: true)

            AWS.upload_avatar(image_params.path, generate_uuid(user.username))

            user = Users.changeset(user, %{avatar: true})
            case Repo.update(user) do
              {:ok, user} ->
                send_resp(conn, :created, "")
              {:error, user} ->
                conn
                |> put_status(:bad_request)
                |> render(Thegm.ErrorView, "error.json", errors: Enum.map(user.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
            end
          true ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `id` was not found"])
        end
    end
  end

  def show(conn, %{"id" => user_id}) do
    case Repo.get(Users, user_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `id` was not found"])
      user ->
        if user.avatar == true do
          avatar_identifier = generate_uuid(user.username)
          conn
          |> put_status(:see_other)
          |> redirect(external: AWS.get_avatar_location(avatar_identifier))

        else
          conn
          |> put_status(:not_found)
          |> render(Thegm.ErrorView, "error.json", errors: ["This user has no avatar"])
      end
    end
  end

  def delete(conn, %{"users_id" => user_id}) do
    current_user_id = conn.assigns[:current_user].id

    case Repo.get(Users, user_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `id` was not found"])
      user ->
        cond do
          current_user_id == user_id ->
            avatar_identifier = generate_uuid(user.username)
            AWS.remove_avatar(avatar_identifier)

            user = Users.changeset(user, %{avatar: false})
            case Repo.update(user) do
              {:ok, user} ->
                send_resp(conn, :gone, "")
              {:error, user} ->
                conn
                |> put_status(:bad_request)
                |> render(Thegm.ErrorView, "error.json", errors: Enum.map(user.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
            end
          true ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `id` was not found"])
        end
    end
  end

  def generate_uuid(resource_identifier) do
    UUID.uuid5(@uuid_namespace, resource_identifier)
  end
end
