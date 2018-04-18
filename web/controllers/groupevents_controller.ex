defmodule Thegm.GroupEventsController do
  use Thegm.Web, :controller

  alias Thegm.GroupEvents
  alias Thegm.GroupMembers

  def create(conn, %{"groups_id" => groups_id, "data" => %{"attributes" => params, "type" => type}}) do
    users_id = conn.assigns[:current_user].id
    case Repo.one(from gm in Thegm.GroupMembers, where: gm.groups_id == ^groups_id and gm.users_id == ^users_id and gm.active == true) do
      nil ->
        conn
        |> put_status(:forbidden)
        |> render(Thegm.ErrorView, "error.json", errors: ["Must be a member of the group"])
      member ->
        cond do
          GroupMembers.isAdmin(member) ->
            case {type, params} do
              {"events", params} ->
                case read_start_end(params) do
                  {:ok, settings} ->
                    params = Map.put(params, "start_time", settings.start_time)
                    params = Map.put(params, "end_time", settings.end_time)
                    params = Map.put(params, "groups_id", groups_id)
                    event_changeset = GroupEvents.create_changeset(%GroupEvents{}, params)

                    case Repo.insert(event_changeset) do
                      {:ok, event} ->
                        event = event |> Repo.preload([:groups, :games])
                        conn
                        |> put_status(:created)
                        |> render("show.json", event: event, is_member: true)
                      {:error, resp} ->
                        error_list = Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end)
                        conn
                        |> put_status(:bad_request)
                        |> render(Thegm.ErrorView, "error.json", errors: error_list)
                    end
                  {:error, errors} ->
                    conn
                    |> put_status(:bad_request)
                    |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                end
              _ ->
                conn
                |> put_status(:bad_request)
                |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `evets` data type"])
            end
          true ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["Must be a group admin to take this action"])
        end
    end
  end

  def update(conn, %{"groups_id" => groups_id, "id" => events_id, "data" => %{"attributes" => params, "type" => type}}) do
    users_id = conn.assigns[:current_user].id

    # Ensure the user is a member of the group
    member = case Repo.one(from gm in Thegm.GroupMembers, where: gm.groups_id == ^groups_id and gm.users_id == ^users_id and gm.active == true) do
      nil ->
        conn
        |> put_status(:forbidden)
        |> render(Thegm.ErrorView, "error.json", errors: ["Must be a member of the group"])
        |> halt()
      member ->
        member
    end

    # Ensure the member is an admin of the group
    unless GroupMembers.isAdmin(member) do
      conn
      |> put_status(:forbidden)
      |> render(Thegm.ErrorView, "error.json", errors: ["Must be a group admin to take this action"])
      |> halt()
    end

    # Ensure received data type is `events`
    unless type == "events" do
      conn
      |> put_status(:bad_request)
      |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `evets` data type"])
      |> halt()
    end

    # Get the event specified
    event = case Repo.get(Thegm.GroupEvents, events_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["No event with that id found"])
        |> halt
      event ->
        event
    end

    # Read the start and end times
    params = case read_start_end(params) do
      {:ok, settings} ->
        params = Map.put(params, "start_time", settings.start_time)
        params = Map.put(params, "end_time", settings.end_time)
        params = Map.put(params, "groups_id", groups_id)
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
        |> halt()
    end

    # Update the event
    event_changeset = GroupEvents.update_changeset(event, params)

    # Attempt to update the event in the database
    case Repo.update(event_changeset) do
      {:ok, event} ->
        event = event |> Repo.preload([:groups, :games])
        conn
        |> put_status(:created)
        |> render("show.json", event: event, is_member: true)
      {:error, resp} ->
        error_list = Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end)
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: error_list)
    end
  end

  def show(conn, %{"groups_id" => groups_id, "id" => events_id}) do
    users_id = case conn.assigns[:current_user] do
      nil ->
        nil
      found ->
        found.id
    end

    case Repo.one(from ge in GroupEvents, where: ge.groups_id == ^groups_id and ge.id == ^events_id) |> Repo.preload([:groups, :games]) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Could not find specified event for group"])
      event ->
        cond do
          event.deleted ->
            conn
            |> put_status(:gone)
            |> render(Thegm.ErrorView, "error.json", errors: ["That event no longer exists."])
          true ->
            is_member = Thegm.GroupMembersController.is_member(groups_id: groups_id, users_id: users_id)
            conn
            |> put_status(:ok)
            |> render("show.json", event: event, is_member: is_member)
        end
    end
  end

  def index(conn, params) do
    users_id = case conn.assigns[:current_user] do
      nil ->
        nil
      found ->
        found.id
    end

    case read_search_params(params) do
      {:ok, settings} ->
        is_member = Thegm.GroupMembersController.is_member(groups_id: settings.groups_id, users_id: users_id)

        # Search params
        offset = (settings.page - 1) * settings.limit
        now = NaiveDateTime.utc_now()

        # Get total in search
        total = Repo.one(from ge in GroupEvents, where: ge.groups_id == ^settings.groups_id and ge.end_time >= ^now and ge.deleted == false, select: count(ge.id))
        cond do
          total > 0 ->
            events =  Repo.all(from ge in GroupEvents,
              where: ge.groups_id == ^settings.groups_id and ge.end_time >= ^now and ge.deleted == false,
              order_by: [asc: ge.start_time],
              limit: ^settings.limit,
              offset: ^offset
            ) |> Repo.preload([:groups, :games])

            meta = %{total: total, limit: settings.limit, offset: offset, count: length(events)}

            conn
            |> put_status(:ok)
            |> render("index.json", events: events, meta: meta, is_member: is_member)
          true ->
            meta = %{total: total, limit: settings.limit, offset: offset, count: 0}
            conn
            |> put_status(:ok)
            |> render("index.json", events: [], meta: meta, is_member: is_member)
        end
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
    end
  end

  def delete(conn, %{"groups_id" => groups_id, "id" => events_id}) do
    users_id = conn.assigns[:current_user].id
    case Repo.one(from gm in Thegm.GroupMembers, where: gm.groups_id == ^groups_id and gm.users_id == ^users_id and gm.active == true) do
      nil ->
        conn
        |> put_status(:forbidden)
        |> render(Thegm.ErrorView, "error.json", errors: ["Must be a member of the group"])
      member ->
        cond do
          GroupMembers.isAdmin(member) ->
            case Repo.get(Thegm.GroupEvents, events_id) do
              nil ->
                conn
                |> put_status(:not_found)
                |> render(Thegm.ErrorView, "error.json", errors: ["No event with that id found"])
              event ->
                event_changeset = GroupEvents.delete_changeset(event)

                case Repo.update(event_changeset) do
                  {:ok, _} ->
                    send_resp(conn, :no_content, "")
                  {:error, resp} ->
                    error_list = Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end)
                    conn
                    |> put_status(:bad_request)
                    |> render(Thegm.ErrorView, "error.json", errors: error_list)
                end
            end
          true ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["Must be a group admin to take this action"])
        end
    end
  end

  def read_start_end(params) do
    errors = []

    # parse start_time
    {start_time, errors} = case params["start_time"] do
      nil ->
        errors = errors ++ [start_time: "Must provide a startime in iso8601 format"]
        {nil, errors}
      start ->
        case DateTime.from_iso8601(start) do
          {:ok, datetime, _} ->
            {datetime, errors}
          {:error, error} ->
            errors = errors ++ [start_time: Atom.to_string(error)]
            {nil, errors}
        end
    end

    # parse end_time
    {end_time, errors} = case params["end_time"] do
      nil ->
        errors = errors ++ [end_time: "Must provide a startime in iso8601 format"]
        {nil, errors}
      ending ->
        case DateTime.from_iso8601(ending) do
          {:ok, datetime, _} ->
            {datetime, errors}
          {:error, error} ->
            errors = errors ++ [end_time: Atom.to_string(error)]
            {nil, errors}
        end
    end

    cond do
      length(errors) > 0 ->
        {:error, errors}
      true ->
        {:ok, %{start_time: start_time, end_time: end_time}}
    end
  end

  defp read_search_params(params) do
    errors = []

    # verify groups_id
    {groups_id, errors} = case params["groups_id"] do
      nil ->
        errors = errors ++ [groups_id: "Must be supplied"]
        {nil, errors}
      temp ->
        {temp, errors}
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
        {:ok, %{page: page, limit: limit, groups_id: groups_id}}
    end
    resp
  end
end
