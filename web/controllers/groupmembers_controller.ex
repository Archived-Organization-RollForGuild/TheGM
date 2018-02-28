defmodule Thegm.GroupMembersController do
  use Thegm.Web, :controller

  alias Thegm.GroupMembers
  alias Thegm.Groups

  def index(conn, %{"groups_id" => group_id}) do
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

  def delete(conn, %{"groups_id" => group_id, "id" => user_id}) do
    current_user_id = conn.assigns[:current_user].id

    case Repo.get(Groups, group_id) |> Repo.preload(:group_members) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Group not found, maybe you already deleted it?"])
      group ->

        current_user_member = Enum.find(group.group_members, fn x -> x.users_id == current_user_id end)
        target_member = Enum.find(group.group_members, fn x -> x.users_id == user_id end)

        cond do
          target_member == nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["members: Is not a member of the group"])

          current_user_member == nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["members: You are not a member of the group"])

          current_user_member.role != "admin" && current_user_id != user_id ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["You do not have permission to remove this user"])


          target_member.role == "admin" ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["Admins cannot be removed from the group"])

          true ->
            case Repo.delete(target_member) do
              {:ok, _} ->
                send_resp(conn, :no_content, "")
              {:error, changeset} ->
                conn
                |> put_status(:internal_server_error)
                |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
            end
        end
    end
  end
end
