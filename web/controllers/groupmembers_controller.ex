defmodule Thegm.GroupMembersController do
  use Thegm.Web, :controller

  alias Thegm.GroupMembers
  alias Thegm.Groups

  def index(conn, %{"groups_id" => groups_id}) do
    users_id = conn.assigns[:current_user].id
    case Repo.all(from m in GroupMembers, where: m.groups_id == ^groups_id) |> Repo.preload(:users) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Group members could not be located"])
      resp ->
        case Enum.any?(resp, fn x -> x.users_id == users_id end) do
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

  def update(conn, %{"groups_id" => groups_id, "id" => users_id, "data" => %{"attributes" => %{"role" => role}}}) do
    current_user_id = conn.assigns[:current_user].id

    case Repo.get(Groups, groups_id) |> Repo.preload(:group_members) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Group not found, maybe you already deleted it?"])
      group ->
        current_user_member = Enum.find(group.group_members, fn x -> x.users_id == current_user_id end)
        target_member = Enum.find(group.group_members, fn x -> x.users_id == users_id end)

        cond do
          role == "owner" ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["members: Members cannot be changed to owner"])

          target_member == nil or GroupMembers.isMember(target_member) == false ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["members: Is not a member of the group"])

          current_user_member == nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["members: You are not a member of the group"])

          GroupMembers.isOwner(current_user_member) == false ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["members: You do not have permission to change user roles"])

          true ->
            member = GroupMembers.role_changeset(target_member, %{role: role})

            case Repo.update(member) do
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

  def delete(conn, %{"groups_id" => groups_id, "id" => users_id}) do
    current_user_id = conn.assigns[:current_user].id

    case Repo.get(Groups, groups_id) |> Repo.preload(:group_members) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Group not found, maybe you already deleted it?"])
      group ->

        current_user_member = Enum.find(group.group_members, fn x -> x.users_id == current_user_id end)
        target_member = Enum.find(group.group_members, fn x -> x.users_id == users_id end)

        cond do
          target_member == nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["members: Is not a member of the group"])

          current_user_member == nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["members: You are not a member of the group"])

          GroupMembers.isAdmin(current_user_member) == false && current_user_id != users_id ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["You do not have permission to remove this user"])

          GroupMembers.isAdmin(target_member) ->
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

  def is_member(groups_id: groups_id, users_id: users_id) do
    cond do
      users_id == nil ->
        false
      true ->
        case Repo.one(from gm in GroupMembers, where: gm.groups_id == ^groups_id and gm.users_id == ^users_id and gm.active == true) do
          nil ->
            false
          _ ->
            true
        end
    end
  end

  def is_member([], users_id: _) do
    false
  end

  # list should be of group members
  # Runtime O(n)
  def is_member([head, tail], users_id: users_id) do
    cond do
      head.users_id == users_id and head.active ->
        true
      true ->
        is_member(tail, users_id: users_id)
    end
  end
end
