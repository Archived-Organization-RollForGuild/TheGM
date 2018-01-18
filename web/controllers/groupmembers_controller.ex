defmodule Thegm.GroupMembersController do
  use Thegm.Web, :controller

  alias Thegm.GroupMembers

  def index(conn, %{"group_id" => group_id}) do
    user_id = conn.assigns[:current_user].id
    case Repo.all(from m in GroupMembers, where: m.groups_id == ^group_id) |> Repo.preload(:users) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Group members could not be located"])
      resp ->
        case Enum.any?(resp, fn x -> x.users_id == user_id end) do
          true ->
            conn
            |> put_status(:ok)
            |> render("members.json", members: resp)
          false ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["You must be a member of the group to view the members"])
        end
    end
  end
end
