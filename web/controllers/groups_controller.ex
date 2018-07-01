defmodule Thegm.GroupsController do
  use Thegm.Web, :controller

  alias Thegm.Groups
  alias Ecto.Multi
  alias Thegm.GroupMembers

  def create(conn, %{"data" => %{"attributes" => params, "type" => type}}) do
    users_id = conn.assigns[:current_user].id
    with {:ok, _} <- Thegm.Validators.validate_type(type, "groups"),
      {:ok, params} <- parse_params(params),
      group_changeset <- Groups.create_changeset(%Groups{}, params),
      {:ok, multi} <- create_group_multi(group_changeset, users_id),
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
    users_id = conn.assigns[:current_user].id
    with {:ok, pagination_params} <- Thegm.Reader.read_pagination_params(params),
      {:ok, geo_params} <- Thegm.Reader.read_geo_search_params(params, 40_075_000),
      settings <- Map.merge(pagination_params, geo_params),
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
    users_id = conn.assigns[:current_user].id
    with {:ok, group} <- Thegm.Groups.get_group_by_id!(groups_id),
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
    with {:ok, _} <- Thegm.Validators.validate_type(type, "groups"),
      {:ok, _} <- Thegm.GroupMembers.is_member_and_admin?(users_id, groups_id),
      {:ok, params} <- parse_params(params),
      {:ok, params_games, games_status} <- Thegm.Reader.read_games_and_status(params),
      {:ok, params_game_suggestions, game_suggestions_status} <- Thegm.Reader.read_game_suggestions_and_status(params),
      {:ok, group} <- Thegm.Groups.get_group_by_id!(groups_id),
      {:ok, games} <- Thegm.GameCompiling.compile_game_changesets(params_games, :groups_id, group.id),
      {:ok, game_suggestions} <- Thegm.GameCompiling.compile_game_suggestion_changesets(params_game_suggestions, :groups_id, group.id),
      group_changeset <- Groups.update_changeset(group, params),
      #{:ok, updated_group} <- Repo.update(group_changeset),
      {:ok, multi} <- create_update_group_with_games_list_multi(group_changeset, games_status, game_suggestions_status, games ++ game_suggestions),
      {:ok, resp} <- Repo.transaction(multi),
      group <- Repo.preload(resp.groups, [{:group_members, :users}]) do
      #group <- Repo.preload(updated_group, [{:group_members, :users}]) do
        conn
        |> put_status(:ok)
        |> render("show.json", group: group, users_id: users_id)
    else
      {:error, :not_found, error} ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: error)
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

  defp create_update_group_with_games_list_multi(group_changeset, games_status, game_suggestions_status, games_list) do
    multi = Multi.new
    |> Multi.update(:groups, group_changeset)

    multi = cond do
      games_status == :replace and game_suggestions_status == :replace ->
        multi |> Multi.delete_all(:remove_group_games, from(gg in Thegm.GroupGames, where:  gg.groups_id == ^group_changeset.data.id))
      games_status == :replace and game_suggestions_status == :skip ->
        multi |> Multi.delete_all(:remove_group_games, from(gg in Thegm.GroupGames, where:  gg.groups_id == ^group_changeset.data.id and not is_nil(gg.games_id)))
      games_status == :skip and game_suggestions_status == :replace ->
        multi |> Multi.delete_all(:remove_group_games,from(gg in Thegm.GroupGames, where: gg.groups_id == ^group_changeset.data.id and not is_nil(gg.game_suggestions_id)))
      true ->
        multi
    end

    multi = if games_status == :replace or game_suggestions_status == :replace do
      multi |> Multi.insert_all(:inserg_group_games, Thegm.GroupGames, games_list)
    else
      multi
    end

    {:ok, multi}
  end

  defp create_group_multi(group_changeset, users_id) do
    multi =
      Multi.new
      |> Multi.insert(:groups, group_changeset)
      |> Multi.run(:group_members, fn %{groups: group} ->
        member_changeset =
          %Thegm.GroupMembers{groups_id: group.id}
          |> Thegm.GroupMembers.create_changeset(%{role: "owner", users_id: users_id})
        Repo.insert(member_changeset)
      end)

    {:ok, multi}
  end
end
