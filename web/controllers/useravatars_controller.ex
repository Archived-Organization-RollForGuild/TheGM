defmodule Thegm.UserAvatarsController do
  @uuid_namespace UUID.uuid5(:url, "https://rollforguild.com/users/avatar")
  use Thegm.Web, :controller

  alias Thegm.Users
  alias Thegm.AWS

  import Mogrify

  def create(conn, %{"id" => user_id, "file" => image_params}) do
    current_user_id = conn.assigns[:current_user].id

    case Repo.get(Users, user_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `id` was not found"])
      user ->
        cond do
          current_user_id == user_id ->
            open(image_params.path)
            |> resize("512x512")
            |> format("jpg")
            |> save(in_place: true)

            {:ok, image_binary} = File.read(image_params.path)

            AWS.upload_avatar(image_binary, generate_uuid(user.username))

            user = Users.changeset(user, %{avatar: true})
            case Repo.update(user) do
              {:ok, user} ->
                render conn, "private.json", user: user
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
