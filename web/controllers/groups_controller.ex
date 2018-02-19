defmodule Thegm.GroupsController do
  use Thegm.Web, :controller

  alias Thegm.Groups
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
              |> Thegm.GroupMembers.changeset(%{role: "admin", users_id: conn.assigns[:current_user].id})
            Repo.insert(member_changeset)
          end)

        case Repo.transaction(multi) do
          {:ok, result} ->
            group = Repo.preload(result.groups, [{:group_members, :users}])
            conn
            |> put_status(:created)
            |> render("memberof.json", group: group)
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
    case read_search_params(params) do
      {:ok, settings} ->
        user_id = conn.assigns[:current_user].id
        # Get user's current groups so we can properly exclude them
        memberships = Repo.all(from m in Thegm.GroupMembers, where: m.users_id == ^user_id, select: m.groups_id)
        blocks = Repo.all(from b in Thegm.GroupBlockedUsers, where: b.user_id == ^user_id and b.rescinded == false, select: b.group_id)
        # Group search params
        offset = (settings.page - 1) * settings.limit
        geom = %Geo.Point{coordinates: {settings.lon, settings.lat}, srid: 4326}

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
              order_by: [asc: st_distancesphere(g.geom, ^geom)],
              limit: ^settings.limit,
              offset: ^offset) |> Repo.preload(:group_members)

            meta = %{total: total, limit: settings.limit, offset: offset, count: length(groups)}

            conn
            |> put_status(:ok)
            |> render("search.json", groups: groups, meta: meta)
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
    case Repo.get(Groups, group_id) |> Repo.preload([{:group_members, :users}]) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["A group with the specified `id` was not found"])
      group ->
        case get_member(group.group_members, user_id) do
          nil ->
            conn
            |> put_status(:ok)
            |> render("notmember.json", group: group)
          member ->
            cond do
              member.role == "member" ->
                conn
                |> put_status(:ok)
                |> render("memberof.json", group: group)
              member.role == "admin" ->
                #todo things for admins
                conn
                |> put_status(:ok)
                |> render("memberof.json", group: group)
            end
        end
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
                    Groups.lat_lon(group)
                  true ->
                    group
                end
                case Repo.update(group) do
                  {:ok, result} ->
                    conn
                    |> put_status(:ok)
                    |> render("memberof.json", group: result.groups)
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
    lat = case params["lat"] do
      nil ->
        errors = errors ++ [lat: "Must be supplied"]
        nil
      temp ->
        {lat, _} = Float.parse(temp)
        if lat > 90 or lat < -90 do
          errors = errors ++ [lat: "Must be between +-90"]
        end
        lat
    end

    # verify lon
    lon = case params["lon"] do
      nil ->
        errors = errors ++ [lon: "Must be supplied"]
        nil
      temp ->
        {lon, _} = Float.parse(temp)
        if lon > 180 or lat < -180 do
          errors = errors ++ [lon: "Must be between +-189"]
        end
        lon
    end

    # set page
    page = case params["page"] do
      nil ->
        page = 1
      temp ->
        {page, _} = Integer.parse(temp)
        if page < 1 do
          errors = errors ++ [page: "Must be a positive integer"]
        end
    end

    meters = case params["meters"] do
      nil ->
        meters = 80467
      temp ->
        {meters, _} = Float.parse(temp)
        if meters <= 0 do
          errors = errors ++ [meters: "Must be a real number greater than 0"]
        end
        meters
    end

    limit = case params["limit"] do
      nil ->
        limit = 100
      temp ->
        {limit, _} = Integer.parse(temp)
        if limit < 1 do
          errors = errors ++ [limit: "Must be at integer greater than 0"]
        end
        limit
    end

    resp = cond do
      length(errors) > 0 ->
        {:error, errors}
      true ->
        {:ok, %{lat: lat, lon: lon, meters: meters, page: page, limit: limit}}
    end
    resp
  end

  def get_member([], _) do
    nil
  end

  def get_member([head | tail], user_id) do
    cond do
      head.users_id == user_id ->
        head
      true ->
        get_member(tail, user_id)
    end
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
end
