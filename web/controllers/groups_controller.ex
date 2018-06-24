defmodule Thegm.GroupsController do
  use Thegm.Web, :controller

  alias Thegm.Groups
  alias Ecto.Multi
  alias Thegm.GroupMembers

  def create(conn, %{"data" => %{"attributes" => params, "type" => type}}) do
    with {:ok, _} <- Thegm.Validators.validate_type(type, "groups"),
      {:ok, params} <- parse_params(params),
      group_changeset <- Groups.create_changeset(%Groups{}, params),
      {:ok, multi} <- create_group_multi(conn, group_changeset),
      {:ok, resp} <- Repo.transaction(multi),
      group <- Repo.preload(resp.groups, [{:group_members, :users}]),
      {:ok, games, game_suggestions} <- Thegm.Reader.read_games_and_game_suggestions(params),
      {:ok, group_games} <- Thegm.GameCompiling.compile_game_changesets(games, :groups_id, group.id),
      {:ok, group_game_suggestions} <- Thegm.GameCompiling.compile_game_suggestion_changesets(game_suggestions, :groups_id, group.id) do
        # Inserting games is separate than group multi as games failing should not affect group creation
        Repo.insert_all(Thegm.GroupGames, group_games ++ group_game_suggestions)
        conn
        |> put_status(:created)
        |> render("show.json", group: group, users_id: conn.assigns[:current_user].id)

    else
      {:error, :groups, changeset, %{}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
      {:error, :group_members, changeset, %{}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: [error])
    end
  end

  def delete(conn, %{"id" => groups_id}) do
    users_id = conn.assigns[:current_user].id
    with {:ok, _} <- Thegm.GroupMembers.is_member_and_admin?(users_id, groups_id),
      {1, _} <- Repo.delete_all(from g in Thegm.Groups, where: g.id == ^groups_id) do
        send_resp(conn, :no_content, "")
    else
      {0, _} ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Group not found, maybe you already deleted it?"])
      {:error, error} ->
        conn
        |> put_status(:forbidden)
        |> render(Thegm.ErrorView, "error.json", errors: error)
    end
  end

  def index(conn, params) do
    users_id = conn.assigns[:current_user]
    with {:ok, settings} <- read_search_params(params),
      {:ok, memberships} <- Thegm.GroupMembers.get_group_ids_where_user_is_member(users_id),
      {:ok, blocked_by} <- Thegm.GroupBlockedUsers.get_group_ids_blocking_user(users_id),
      geom <- %Geo.Point{coordinates: {settings.lng, settings.lat}, srid: 4326},
      {:ok, total} <- Thegm.Groups.get_total_groups_with_settings(settings, geom, memberships, blocked_by),
      offset <- (settings.page - 1) * settings.limit,
      {:ok, groups} <- Thegm.Groups.get_groups_with_settings(users_id, settings, geom, memberships, blocked_by, offset) do
        meta = %{total: total, limit: settings.limit, offset: offset, count: length(groups)}
        conn
        |> put_status(:ok)
        |> render("index.json", groups: groups, meta: meta, users_id: users_id)
    else
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: error)
    end
  end

  def show(conn, %{"id" => groups_id}) do
    users_id = conn.assigns[:current_user]
    with {:ok, group} <- Thegm.Groups.get_group_by_id(groups_id),
      {:ok, group} <- Thegm.Groups.preload_join_requests_by_requestee_id(group, users_id) do
        conn
        |> put_status(:ok)
        |> render("show.json", group: group, users_id: users_id)
    else
      {:error, :not_found, error} ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: [error])
    end
  end

  def update(conn, %{"id" => groups_id, "data" => %{"attributes" => params, "type" => type}}) do
    users_id = conn.assigns[:current_user].id
    cond do
      type == "groups" ->
        case Repo.one(from m in Thegm.GroupMembers, where: m.groups_id == ^groups_id and m.users_id == ^users_id) |> Repo.preload(:groups) do
          nil ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["membership: You must be a member", "role: You must be an admin"])
          member ->
            cond do
              GroupMembers.isAdmin(member) ->
                params = cond do
                  Map.has_key?(params, "address") && params["address"] != nil ->
                    case Thegm.Geos.get_lat_lng(params["address"]) do
                      {:ok, geo} ->
                        Map.merge(params, %{"lat" => geo[:lat], "lng" => geo[:lng]})
                      {:error, error} ->
                        conn
                        |> put_status(:unprocessable_entity)
                        |> Phoenix.Controller.render(Thegm.ErrorView, "error.json", errors: [error])
                        |> halt()
                    end
                  true ->
                    params
                end
                group = Groups.changeset(member.groups, params)
                case Repo.update(group) do
                  {:ok, _} ->
                    group_response = groups_query(groups_id, users_id)
                    conn
                    |> put_status(:ok)
                    |> render("show.json", group: group_response, users_id: users_id)
                  {:error, changeset} ->
                    conn
                    |> put_status(:unprocessable_entity)
                    |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                end
              true ->
                conn
                |> put_status(:forbidden)
                |> render(Thegm.ErrorView, "error.json", errors: ["role: You must be an admin"])
            end
        end
      true ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `group` data type"])
    end
  end

  defp parse_params(params) do
    cond do
      Map.has_key?(params, "address") && params["address"] != nil ->
        case Thegm.Geos.get_lat_lng(params["address"]) do
          {:ok, geo} ->
            params = Map.merge(params, %{"lat" => geo[:lat], "lng" => geo[:lng]})
            {:ok, params}
          {:error, error} ->
            {:error, error}
        end
      true ->
        {:ok, params}
    end
  end

  defp read_search_params(params) do
    errors = []

    # verify lat
    {lat, errors} = case params["lat"] do
      nil ->
        errors = errors ++ [lat: "Must be supplied"]
        {nil, errors}
      temp ->
        {lat, _} = Float.parse(temp)
        errors = cond do
          lat > 90 or lat < -90 ->
            errors ++ [lat: "Must be between +-90"]
          true ->
            errors
        end
        {lat, errors}
    end

    # verify lng
    {lng, errors} = case params["lng"] do
      nil ->
        errors = errors ++ [lng: "Must be supplied"]
        {nil, errors}
      temp ->
        {lng, _} = Float.parse(temp)
        errors = cond do
          lng > 180 or lat < -180 ->
            errors ++ [lng: "Must be between +-189"]
          true ->
            errors
        end
        {lng, errors}
    end

    # set page
    {page, errors} = case params["page"] do
      nil ->
        {1, errors}
      temp ->
        {page, _} = Integer.parse(temp)
        errors = cond do
          page < 1 ->
            errors ++ [page: "Must be a positive integer"]
          true ->
            errors
        end
        {page, errors}
    end

    {meters, errors} = case params["meters"] do
      nil ->
        {40075000, errors}
      temp ->
        {meters, _} = Float.parse(temp)
        errors = cond do
          meters <= 0 ->
            errors ++ [meters: "Must be a real number greater than 0"]
          true ->
            errors
        end
        {meters, errors}
    end

    {limit, errors} = case params["limit"] do
      nil ->
        {100, errors}
      temp ->
        {limit, _} = Integer.parse(temp)
        errors = cond do

          limit < 1 ->
            errors ++ [limit: "Must be at integer greater than 0"]
          true ->
            errors
        end
        {limit, errors}
    end

    resp = cond do
      length(errors) > 0 ->
        {:error, errors}
      true ->
        {:ok, %{lat: lat, lng: lng, meters: meters, page: page, limit: limit}}
    end
    resp
  end

  def get_admin([], _) do
    nil
  end

  def get_admin([head | tail], users_id) do
    cond do
      head.users_id == users_id and GroupMembers.isAdmin(head) ->
        head
      true ->
        get_admin(tail, users_id)
    end
  end

  def groups_query(groups_id, users_id) do
    join_requests_query = case users_id do
      nil ->
        from gjr in Thegm.GroupJoinRequests, where: is_nil(gjr.users_id), order_by: [desc: gjr.inserted_at]
      _ ->
        from gjr in Thegm.GroupJoinRequests, where: gjr.users_id == ^users_id, order_by: [desc: gjr.inserted_at]
    end

    Repo.one(from g in Groups, where: (g.id == ^groups_id))
    |> Repo.preload([join_requests: join_requests_query, group_members: :users, group_games: :games])
  end

  defp create_group_multi(conn, group_changeset) do
    multi =
      Multi.new
      |> Multi.insert(:groups, group_changeset)
      |> Multi.run(:group_members, fn %{groups: group} ->
        member_changeset =
          %Thegm.GroupMembers{groups_id: group.id}
          |> Thegm.GroupMembers.create_changeset(%{role: "owner", users_id: conn.assigns[:current_user].id})
        Repo.insert(member_changeset)
      end)

    {:ok, multi}
  end
end
