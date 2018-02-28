defmodule Thegm.GroupsController do
  use Thegm.Web, :controller

  alias Thegm.Groups
  alias Thegm.GroupJoinRequests
  alias Ecto.Multi
  import Geo.PostGIS

  def create(conn, %{"data" => %{"attributes" => params, "type" => type}}) do
    case {type, params} do
      {"groups", params} ->
        group_changeset = Groups.create_changeset(%Groups{}, params)
        multi =
          Multi.new
          |> Multi.insert(:groups, group_changeset)
          |> Multi.run(:group_members, fn %{groups: group} ->
            member_changeset =
              %Thegm.GroupMembers{groups_id: group.id}
              |> Thegm.GroupMembers.create_changeset(%{role: "admin", users_id: conn.assigns[:current_user].id})
            Repo.insert(member_changeset)
          end)

        case Repo.transaction(multi) do
          {:ok, result} ->
            group = Repo.preload(result.groups, [{:group_members, :users}])

            conn
            |> put_status(:created)
            |> render("memberof.json", group: group, user: conn.assigns[:current_user])
          {:error, :groups, changeset, %{}} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
          {:error, :group_members, changeset, %{}} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
        end
      _ ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `group` data type"])
    end
  end

  def delete(conn, %{"id" => group_id}) do
    user_id = conn.assigns[:current_user].id
    case Repo.get(Groups, group_id) |> Repo.preload(:group_members) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Group not found, maybe you already deleted it?"])
      group ->
        case Enum.find(group.group_members, fn x -> x.users_id == user_id end) do
          nil ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["members: Must be member of group", "role: Must be admin of group"])
          member ->
            cond do
              member.role != "admin" ->
                conn
                |> put_status(:forbidden)
                |> render(Thegm.ErrorView, "error.json", errors: ["role: Must be admin"])
              member.role == "admin" ->
                case Repo.delete(group) do
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

  def index(conn, params) do
    user_id = conn.assigns[:current_user].id
    case read_search_params(params) do
      {:ok, settings} ->
        user_id = conn.assigns[:current_user].id
        # Get user's current groups so we can properly exclude them
        memberships = Repo.all(from m in Thegm.GroupMembers, where: m.users_id == ^user_id, select: m.groups_id)
        blocks = Repo.all(from b in Thegm.GroupBlockedUsers, where: b.user_id == ^user_id and b.rescinded == false, select: b.group_id)
        # Group search params
        offset = (settings.page - 1) * settings.limit
        geom = %Geo.Point{coordinates: {settings.lng, settings.lat}, srid: 4326}

        # Get total in search
        total = Repo.one(from g in Groups,
        select: count(g.id),
        where: st_distancesphere(g.geom, ^geom) <= ^settings.meters and not g.id in ^memberships and g.discoverable == true)

        # Do the search
        cond do
          total > 0 ->
            groups = Repo.all(
              from g in Groups,
              select: %{g | distance: st_distancesphere(g.geom, ^geom)},
              where: st_distancesphere(g.geom, ^geom) <= ^settings.meters and not g.id in ^memberships and not g.id in ^blocks and g.discoverable == true,
              left_join: gm in assoc(g, :group_members),
              left_join: u in assoc(gm, :users),
              left_join: gjr in GroupJoinRequests, on: gjr.group_id == g.id and gjr.user_id == ^user_id,
              preload: [group_members: {gm, users: u}, join_requests: gjr],
              order_by: [asc: st_distancesphere(g.geom, ^geom)],
              limit: ^settings.limit,
              offset: ^offset,
              preload: [group_members: {gm, users: u}, join_requests: gjr])

            meta = %{total: total, limit: settings.limit, offset: offset, count: length(groups)}

            conn
            |> put_status(:ok)
            |> render("search.json", groups: groups, meta: meta, user: conn.assigns[:current_user])
          true ->
            meta = %{total: total, limit: settings.limit, offset: offset, count: 0}
            conn
            |> put_status(:ok)
            |> render("search.json", groups: [], meta: meta)
        end
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
    end
  end

  def show(conn, %{"id" => group_id}) do
    user_id = conn.assigns[:current_user].id

    case Repo.one(groups_query(group_id, user_id)) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["A group with the specified `id` was not found"])
      group ->
        conn
        |> put_status(:ok)
        |> render("adminof.json", group: group, user: conn.assigns[:current_user])
    end
  end

  def update(conn, %{"id" => group_id, "data" => %{"attributes" => params, "type" => type}}) do
    user_id = conn.assigns[:current_user].id
    cond do
      type == "groups" ->
        case Repo.one(from m in Thegm.GroupMembers, where: m.groups_id == ^group_id and m.users_id == ^user_id) |> Repo.preload(:groups) do
          nil ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["membership: You must be a member", "role: You must be an admin"])
          member ->
            cond do
              member.role == "admin" ->
                group = Groups.changeset(member.groups, params)
                group = cond do
                  Map.has_key?(group.changes, :address) ->
                    Groups.lat_lng(group)
                  true ->
                    group
                end
                case Repo.update(group) do
                  {:ok, _} ->
                    group_response = Repo.one(groups_query(group_id, user_id))

                    conn
                    |> put_status(:ok)
                    |> render("adminof.json", group: group_response, user: conn.assigns[:current_user])
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
        {80467, errors}
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

  def get_admin([head | tail], user_id) do
    cond do
      head.users_id == user_id and head.role == "admin" ->
        head
      true ->
        get_admin(tail, user_id)
    end
  end

  def groups_query(group_id, user_id) do
    from g in Groups,
         left_join: gm in assoc(g, :group_members),
         left_join: u in assoc(gm, :users),
         left_join: gjr in GroupJoinRequests, on: gjr.group_id == g.id and gjr.user_id == ^user_id,
         where: (g.id == ^group_id),
         preload: [group_members: {gm, users: u}, join_requests: gjr]
  end
end
