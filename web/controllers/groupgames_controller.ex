defmodule Thegm.GroupGamesController do
  use Thegm.Web, :controller

  alias Thegm.GroupGames
  alias Thegm.Groups
  alias Ecto.Multi

  def index(conn, %{"groups_id" => groups_id}) do
    case Repo.all(from gg in GroupGames, where: gg.groups_id == ^groups_id) |> Repo.preload(:games) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Group games could not be located"])
      resp ->
        conn
        |> put_status(:ok)
        |> render("index.json", members: resp)
    end
  end

  def create(conn, %{"groups_id" => groups_id, "data" => groupgames}) do
    users_id = conn.assigns[:current_user].id

    case Repo.get(Groups, groups_id) |> Repo.preload(:group_games) |> Repo.preload(:group_members) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Group not found"])
      group ->
        current_user_member = Enum.find(group.group_members, fn x -> x.users_id == users_id end)

        cond do
          current_user_member == nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["members: You are not a member of the group"])

          current_user_member.role != "admin" ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["You do not have permission to add games"])

          true ->
            invalid_items = Enum.reject(groupgames, fn x -> x["type"] == "group-games" end)

            unless length(invalid_items) > 0 do
              groupgames = Enum.map(groupgames, fn (groupgame) ->
                %{
                  id: UUID.uuid4,
                  groups_id: groups_id,
                  games_id: groupgame["id"],
                  inserted_at: NaiveDateTime.utc_now(),
                  updated_at: NaiveDateTime.utc_now()
                }
              end)

              case Repo.insert_all(GroupGames, groupgames, [on_conflict: :nothing]) do
                {_, nil} ->
                  send_resp(conn, :no_content, "")
                {:error, changeset} ->
                  conn
                  |> put_status(:internal_server_error)
                  |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
              end
            else
              conn
              |> put_status(:bad_request)
              |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `group-games` data type"])
            end
        end
    end
  end

  def update(conn, %{"groups_id" => groups_id, "data" => groupgames}) do
    users_id = conn.assigns[:current_user].id

    case Repo.get(Groups, groups_id) |> Repo.preload(:group_games) |> Repo.preload(:group_members) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Group not found"])
      group ->
        current_user_member = Enum.find(group.group_members, fn x -> x.users_id == users_id end)

        cond do
          current_user_member == nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["members: You are not a member of the group"])

          current_user_member.role != "admin" ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["You do not have permission to modify games"])

          true ->
            invalid_items = Enum.reject(groupgames, fn x -> x["type"] == "group-games" end)

            unless length(invalid_items) > 0 do
              groupgames = Enum.map(groupgames, fn (groupgame) ->
                %{
                  id: UUID.uuid4,
                  groups_id: groups_id,
                  games_id: groupgame["id"],
                  inserted_at: NaiveDateTime.utc_now(),
                  updated_at: NaiveDateTime.utc_now()
                }
              end)

              transaction = Multi.new
              |> Multi.delete_all(:remove_groupgames, from(gg in GroupGames, where: gg.groups_id == ^groups_id))
              |> Multi.insert_all(:add_groupgames, GroupGames, groupgames, [on_conflict: :nothing])

              case Repo.transaction(transaction) do
                {:ok, _} ->
                  send_resp(conn, :no_content, "")
                {:error, _, changeset, _} ->
                  conn
                  |> put_status(:internal_server_error)
                  |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
              end
            else
              conn
              |> put_status(:bad_request)
              |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `group-games` data type"])
            end
        end
    end
  end

  def delete(conn, %{"groups_id" => groups_id, "id" => games_id}) do
    current_user_id = conn.assigns[:current_user].id

    case Repo.get(Groups, groups_id) |> Repo.preload(:group_games) |> Repo.preload(:group_members) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Group not found"])
      group ->

        current_user_member = Enum.find(group.group_members, fn x -> x.users_id == current_user_id end)
        target_game = Enum.find(group.group_games, fn x -> x.games_id == games_id end)

        cond do
          current_user_member == nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["members: You are not a member of the group"])

          current_user_member.role != "admin" ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["You do not have permission to remove this game"])


          target_game == nil ->
            send_resp(conn, :no_content, "")

          true ->
            case Repo.delete(target_game) do
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
