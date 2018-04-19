defmodule Thegm.GroupEventsController do
  use Thegm.Web, :controller

  alias Thegm.GroupEvents
  alias Thegm.GroupMembers

  def create(conn, %{"groups_id" => groups_id, "data" => %{"attributes" => params, "type" => "events"}}) do
    users_id = conn.assigns[:current_user].id

    # Ensure user is a member and admin of the group
    case is_member_and_admin?(users_id, groups_id) do
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: error)
        |> halt()
      {:ok, _} ->
        nil
    end

    # # Ensure received data type is `events`
    # unless type == "events" do
    #   conn
    #   |> put_status(:bad_request)
    #   |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `events` data type"])
    #   |> halt()
    # end

    # Read start/end time params
    params = case read_start_and_end_times(params) do
      {:ok, settings} ->
        params
        |> Map.put("start_time", settings.start_time)
        |> Map.put("end_time", settings.end_time)
        |> Map.put("groups_id", groups_id)
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
        |> halt()
    end

    # Create event changeset
    event_changeset = GroupEvents.create_changeset(%GroupEvents{}, params)

    # Attept to insert event changeset
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
        |> halt()
    end
  end

  def update(conn, %{"groups_id" => groups_id, "id" => events_id, "data" => %{"attributes" => params, "type" => "events"}}) do
    users_id = conn.assigns[:current_user].id

    # Ensure user is a member and admin of the group
    case is_member_and_admin?(users_id, groups_id) do
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: error)
        |> halt()
      {:ok, _} ->
        nil
    end

    # # Ensure received data type is `events`
    # unless type == "events" do
    #   conn
    #   |> put_status(:bad_request)
    #   |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `events` data type"])
    #   |> halt()
    # end

    # Get the event specified
    event = case Repo.get(Thegm.GroupEvents, events_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["No event with that id found"])
        |> halt()
      event ->
        event
    end

    # Read the start and end times
    params = case read_start_and_end_times(params) do
      {:ok, settings} ->
        params
        |> Map.put("start_time", settings.start_time)
        |> Map.put("end_time", settings.end_time)
        |> Map.put("groups_id", groups_id)
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
        |> halt()
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
        if event.deleted do
          conn
          |> put_status(:gone)
          |> render(Thegm.ErrorView, "error.json", errors: ["That event no longer exists."])
        else
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

    groups_id = params["groups_id"]
    if groups_id == nil do
      conn
      |> put_status(:bad_request)
      |> render(Thegm.ErrorView, "error.json", errors: ["groups_id: Must be supplied!"])
      |> halt()
    end

    settings = case Thegm.ReadPagination.read_pagination_params(params) do
      {:ok, settings} ->
        settings
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
        |> halt()
    end

    {meta, events} = query_events_with_meta(groups_id, settings)

    # Is the user a member?
    is_member = Thegm.GroupMembersController.is_member(groups_id: groups_id, users_id: users_id)

    conn
    |> put_status(:ok)
    |> render("index.json", events: events, meta: meta, is_member: is_member)
  end

  def delete(conn, %{"groups_id" => groups_id, "id" => events_id}) do
    users_id = conn.assigns[:current_user].id

    # Ensure user is a member and admin of the group
    case is_member_and_admin?(users_id, groups_id) do
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: error)
        |> halt()
      {:ok, _} ->
        nil
    end

    # Get the specified event
    event = case Repo.get(Thegm.GroupEvents, events_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["No event with that id found"])
        |> halt()
      event ->
        event
    end

    # Mark event as deleted
    event_changeset = GroupEvents.delete_changeset(event)

    # Update event to be known as deleted
    case Repo.update(event_changeset) do
      {:ok, _} ->
        send_resp(conn, :no_content, "")
      {:error, resp} ->
        error_list = Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end)
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: error_list)
        |> halt()
    end
  end

  def read_start_and_end_times(params) do
    errors = []

    {start_time, errors} = read_start_time(params, errors)
    {end_time, errors} = read_end_time(params, errors)

    if length(errors) > 0 do
        {:error, errors}
    else
        {:ok, %{start_time: start_time, end_time: end_time}}
    end
  end

  defp read_start_time(params, errors) do
    case params["start_time"] do
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
  end

  defp read_end_time(params, errors) do
    case params["end_time"] do
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
  end

  defp is_member_and_admin?(users_id, groups_id) do
    # Ensure user is a member of group
    case Repo.one(from gm in Thegm.GroupMembers, where: gm.groups_id == ^groups_id and gm.users_id == ^users_id and gm.active == true) do
      nil ->
        {:error, ["Must be a member of the group"]}
      member ->
        # Ensure user is an admin of the group
        if GroupMembers.isAdmin(member) do
          {:ok, member}
        else
          {:error, ["Must be a group admin to take this action"]}
        end
    end
  end

  defp query_events_with_meta(groups_id, settings) do
    now = NaiveDateTime.utc_now()

    # Get total in search
    total = Repo.one(from ge in GroupEvents, where: ge.groups_id == ^groups_id and ge.end_time >= ^now and ge.deleted == false, select: count(ge.id))

    events =  Repo.all(from ge in GroupEvents,
      where: ge.groups_id == ^groups_id and ge.end_time >= ^now and ge.deleted == false,
      order_by: [asc: ge.start_time],
      limit: ^settings.limit,
      offset: ^settings.offset
    ) |> Repo.preload([:groups, :games])

    meta = %{total: total, limit: settings.limit, offset: settings.offset, count: length(events)}

    {meta, events}
  end
end
