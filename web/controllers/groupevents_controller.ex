defmodule Thegm.GroupEventsController do
  use Thegm.Web, :controller

  alias Thegm.GroupEvents
  alias Ecto.Multi

  def create(conn, %{"groups_id" => groups_id, "data" => %{"attributes" => params, "type" => type}}) do
    users_id = conn.assigns[:current_user].id
    # Do the base validation
    case Thegm.GroupMembers.is_member_and_admin?(users_id, groups_id) do
      {:ok, _} ->
        if type == "events" do
          create_continued_parse_params(conn, groups_id, users_id, params)
        else
          conn
          |> put_status(:bad_request)
          |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `events` type"])
        end
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: error)
    end
  end

  def create_continued_parse_params(conn, groups_id, users_id, params) do
    {games, game_suggestions} = read_games_and_game_suggestions(params)

    # NOTE: Once we have guilds, this should only be triggered if a group is not a guild.
    if length(games) + length(game_suggestions) <= 1 do
      case read_start_and_end_times(params) do
        {:ok, settings} ->
          params = params
          |> Map.put("start_time", settings.start_time)
          |> Map.put("end_time", settings.end_time)
          |> Map.put("groups_id", groups_id)
          |> Map.put("users_id", users_id)

          create_continued_define_multi_and_insert(conn, params, games, game_suggestions)
        {:error, errors} ->
          conn
          |> put_status(:bad_request)
          |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
      end
    else
      conn
      |> put_status(:bad_request)
      |> render(Thegm.ErrorView, "error.json", errors: ["Events can only have one game associated with them"])
    end
  end

  def create_continued_define_multi_and_insert(conn, params, games, game_suggestions) do
    # Create event changeset
    event_changeset = GroupEvents.create_changeset(%GroupEvents{}, params)

    case Repo.insert(event_changeset) do
      {:ok, event} ->
        event_games = compile_game_changesets(games, event.id) ++ compile_game_suggestion_changesets(game_suggestions, event.id)
        Repo.insert_all(Thegm.GroupEventGames, event_games)

        Task.start(Thegm.GroupEvents, :create_new_event_notification, [event, Map.fetch!(params, "groups_id"), Map.fetch!(params, "users_id")])

        conn
        |> put_status(:created)
        |> render("show.json", event: event |> Repo.preload(:groups), is_member: true)

      {:error, resp} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
    end
  end

  def update(conn, %{"groups_id" => groups_id, "id" => events_id, "data" => %{"attributes" => params, "type" => type}}) do
    users_id = conn.assigns[:current_user].id
    # Do the base validation
    case Thegm.GroupMembers.is_member_and_admin?(users_id, groups_id) do
      {:ok, _} ->
        if type == "events" do
          update_continued_get_event_and_parse_params(conn, events_id, groups_id, users_id, params)
        else
          conn
          |> put_status(:bad_request)
          |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `events` type"])
        end
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: error)
    end
  end

  def update_continued_get_event_and_parse_params(conn, events_id, groups_id, users_id, params) do
    # Get the event specified
    case Repo.get(Thegm.GroupEvents, events_id) |> Repo.preload(:group_event_games) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["No event with that id found"])
      event ->
        # Read the start and end times
        case read_start_and_end_times_optional(params) do
          {:ok, params} ->
            params = params
            |> Map.put("groups_id", groups_id)
            |> Map.put("users_id", users_id)

            update_continued_parse_games_and_game_suggestions(conn, params, event)
          {:error, errors} ->
            conn
            |> put_status(:bad_request)
            |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
        end
    end
  end

  def update_continued_parse_games_and_game_suggestions(conn, params, event) do
    {games, games_status}  = case params["games"] do
      nil ->
        {[], :skip}
      list ->
        {list, :replace}
    end

    {game_suggestions, game_suggestions_status} = case params["game_suggestions"] do
      nil ->
        {[], :skip}
      list ->
        {list, :replace}
    end

    # Update the event
    event_changeset = GroupEvents.update_changeset(event, params)
    # Create list of event games changesets
    event_games = compile_game_changesets(games, event.id) ++ compile_game_suggestion_changesets(game_suggestions, event.id)
    # Will figure out how to go about delete event games, if at all
    update_continued_decide_which_delete_type(conn, event, event_changeset, event_games, games_status, game_suggestions_status)
  end

  def update_continued_decide_which_delete_type(conn, event, event_changeset, event_games, games_status, game_suggestions_status) do
    cond do
      games_status == :replace and game_suggestions_status == :replace ->
        update_and_replace_all(conn, event, event_changeset, event_games)

      games_status == :replace and game_suggestions_status == :skip ->
        update_and_replace_games(conn, event, event_changeset, event_games)

      games_status == :skip and game_suggestions_status == :replace ->
        update_and_replace_game_suggestions(conn, event, event_changeset, event_games)

      games_status == :skip and game_suggestions_status == :skip ->
        update_and_replace_none(conn, event_changeset)
    end
  end

  def update_and_replace_all(conn, event, event_changeset, event_games) do
    multi =
      Multi.new
      |> Multi.update(:group_events, event_changeset)
      |> Multi.delete_all(:remove_all_event_games, from(geg in Thegm.GroupEventGames, where:  geg.group_events_id == ^event.id))
      |> Multi.insert_all(:insert_group_event_games1, Thegm.GroupEventGames, event_games)

    update_continued_transact_multi(conn, multi)
  end

  def update_and_replace_games(conn, event, event_changeset, event_games) do
    multi =
      Multi.new
      |> Multi.update(:group_events, event_changeset)
      |> Multi.delete_all(:remove_event_games, from(geg in Thegm.GroupEventGames, where:  geg.group_events_id == ^event.id and not is_nil(geg.games_id)))
      |> Multi.insert_all(:insert_event_games2, Thegm.GroupEventGames, event_games)

      update_continued_transact_multi(conn, multi)
  end

  def update_and_replace_game_suggestions(conn, event, event_changeset, event_games) do
    multi =
      Multi.new
      |> Multi.update(:group_events, event_changeset)
      |> Multi.delete_all(:remove_event_game_sugestions, from(geg in Thegm.GroupEventGames, where:  geg.group_events_id == ^event.id and not is_nil(geg.game_suggestions_id)))
      |> Multi.insert_all(:insert_group_event_games3, Thegm.GroupEventGames, event_games)

      update_continued_transact_multi(conn, multi)
  end

  def update_and_replace_none(conn, event_changeset) do
    case Repo.update(event_changeset) do
      {:ok, event} ->
        event = event |> Repo.preload([:groups, :group_event_games])
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

  def update_continued_transact_multi(conn, multi) do
    case Repo.transaction(multi) do
      {:ok, resp} ->
        event = resp.group_events |> Repo.preload(:groups)
        conn
        |> put_status(:ok)
        |> render("show.json", event: event, is_member: true)

      {:error, :group_events, changeset, %{}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))

      {:error, :group_event_games, changeset, %{}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
    end
  end

  def games_reduce_and_divide([], games, game_suggestions) do
    {games, game_suggestions}
  end

  def games_reduce_and_divide([head | tail], games, game_suggestions) do
    cond do
      head.games_id != nil ->
        games_reduce_and_divide(tail, games ++ [head.games_id], game_suggestions)
      head.game_suggestions_id != nil ->
        games_reduce_and_divide(tail, games, game_suggestions ++ [head.game_suggestions_id])
      true ->
        games_reduce_and_divide(tail, games, game_suggestions)
    end
  end

  def show(conn, %{"groups_id" => groups_id, "id" => events_id}) do
    users_id = case conn.assigns[:current_user] do
      nil ->
        nil
      found ->
        found.id
    end

    case Repo.one(from ge in GroupEvents, where: ge.groups_id == ^groups_id and ge.id == ^events_id) |> Repo.preload([:groups]) do
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
    if groups_id != nil do
      case Thegm.Reader.read_pagination_params(params) do
        {:ok, settings} ->
          {meta, events} = query_events_with_meta(groups_id, settings)

          # Is the user a member?
          is_member = Thegm.GroupMembersController.is_member(groups_id: groups_id, users_id: users_id)

          conn
          |> put_status(:ok)
          |> render("index.json", events: events, meta: meta, is_member: is_member)
        {:error, errors} ->
          conn
          |> put_status(:bad_request)
          |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
      end
    else
      conn
      |> put_status(:bad_request)
      |> render(Thegm.ErrorView, "error.json", errors: ["groups_id: Must be supplied!"])
    end
  end

  def delete(conn, %{"groups_id" => groups_id, "id" => events_id}) do
    users_id = conn.assigns[:current_user].id

    # Ensure user is a member and admin of the group
    case Thegm.GroupMembers.is_member_and_admin?(users_id, groups_id) do
      {:ok, _} ->
        # Get the specified event
        case Repo.get(Thegm.GroupEvents, events_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["No event with that id found"])
          event ->
            delete_continued_alter_changeset_and_update(conn, event)
        end

      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: error)
    end
  end

  def delete_continued_alter_changeset_and_update(conn, event) do
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

  def read_start_and_end_times_optional(params) do
    errors = []

    {params, errors} = if params["start_time"] != nil do
      {start_time, errors} = read_start_time(params, errors)
      params = Map.put(params, "start_time", start_time)
      {params, errors}
    else
      {params, errors}
    end

    {params, errors} = if params["end_time"] != nil do
      {end_time, errors} = read_end_time(params, errors)
      params = Map.put(params, "end_time", end_time)
      {params, errors}
    else
      {params, errors}
    end

    if length(errors) > 0 do
        {:error, errors}
    else
        {:ok, params}
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

  defp query_events_with_meta(groups_id, settings) do
    now = NaiveDateTime.utc_now()

    # Get total in search
    total = Repo.one(from ge in GroupEvents, where: ge.groups_id == ^groups_id and ge.end_time >= ^now and ge.deleted == false, select: count(ge.id))

    events =  Repo.all(from ge in GroupEvents,
      where: ge.groups_id == ^groups_id and ge.end_time >= ^now and ge.deleted == false,
      order_by: [asc: ge.start_time],
      limit: ^settings.limit,
      offset: ^settings.offset
    ) |> Repo.preload([:groups])

    meta = %{total: total, limit: settings.limit, offset: settings.offset, count: length(events)}

    {meta, events}
  end

  defp read_games_and_game_suggestions(params) do
    games = case params["games"] do
      nil ->
        []
      list ->
        list
    end

    game_suggestions = case params["game_suggestions"] do
      nil ->
        []
      list ->
        list
    end

    {games, game_suggestions}
  end

  def compile_game_changesets([], _) do
    []
  end

  def compile_game_changesets([head | tail], group_events_id) do
    this = %{
      id: UUID.uuid4,
      group_events_id: group_events_id,
      game_suggestions_id: nil,
      games_id: head,
      inserted_at: NaiveDateTime.utc_now(),
      updated_at: NaiveDateTime.utc_now()
    }
    [this] ++ compile_game_changesets(tail, group_events_id)
  end

  def compile_game_suggestion_changesets([], _) do
    []
  end

  def compile_game_suggestion_changesets([head | tail], group_events_id) do
    this = %{
      id: UUID.uuid4,
      group_events_id: group_events_id,
      game_suggestions_id: head,
      games_id: nil,
      inserted_at: NaiveDateTime.utc_now(),
      updated_at: NaiveDateTime.utc_now()
    }
    [this] ++ compile_game_changesets(tail, group_events_id)
  end
end
