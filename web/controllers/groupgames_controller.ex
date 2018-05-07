defmodule Thegm.GroupGamesController do
  use Thegm.Web, :controller

  alias Thegm.GroupGames
  alias Thegm.Groups
  alias Ecto.Multi
  alias Thegm.GroupMembers

  def index(conn, params) do
    case read_params(params) do
      {:ok, settings} ->
        # Get total in search
        total = Repo.one(from gg in GroupGames,
                         select: count(gg.id),
                         where: gg.groups_id == ^settings.groups_id)
        offset = (settings.page - 1) * settings.limit

        cond do
          total > 0 ->
            groupgames = Repo.all(
                           from gg in GroupGames,
                           where: gg.groups_id == ^settings.groups_id,
                           order_by: [desc: gg.inserted_at],
                           limit: ^settings.limit,
                           offset: ^offset) |> Repo.preload(:games)
            meta = %{total: total, limit: settings.limit, offset: offset, count: length(groupgames)}

            conn
            |> put_status(:ok)
            |> render("index.json", groupgames: groupgames, meta: meta)

          true ->
            meta = %{total: total, limit: settings.limit, offset: offset, count: 0}

            conn
            |> put_status(:ok)
            |> render("index.json", groupgames: [], meta: meta)
        end
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView,
             "error.json",
             errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> v end))
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

          GroupMembers.isAdmin(current_user_member) == false ->
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

          GroupMembers.isAdmin(current_user_member) == false ->
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

          GroupMembers.isAdmin(current_user_member) == false ->
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

  defp read_params(params) do
    errors = []

    # set page
    {groups_id, errors} = case params["groups_id"] do
      nil ->
        errors = errors ++ ["groups_id": "must be supplied"]
        {nil, errors}
      temp ->
        {temp, errors}
    end

    # set page
    {page, errors} = case params["page"] do
      nil ->
        page = 1
        {page, errors}
      temp ->
        {page, _} = Integer.parse(temp)
        errors = if page < 1 do
          errors ++ [page: "Must be a positive integer"]
        end
        {page, errors}
    end

    {limit, errors} = case params["limit"] do
      nil ->
        limit = 100
        {limit, errors}
      temp ->
        {limit, _} = Integer.parse(temp)
        errors = if limit < 1 do
          errors ++ [limit: "Must be at integer greater than 0"]
        end
        {limit, errors}
    end

    resp = cond do
      length(errors) > 0 ->
        {:error, errors}
      true ->
        {:ok, %{groups_id: groups_id, page: page, limit: limit}}
    end
    resp
  end
end
# credo:disable-for-this-file
