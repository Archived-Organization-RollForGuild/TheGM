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
                        |> render("show.json", event: event)
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
    case Repo.one(from gm in Thegm.GroupMembers, where: gm.groups_id == ^groups_id and gm.users_id == ^users_id and gm.active == true) do
      nil ->
        conn
        |> put_status(:forbidden)
        |> render(Thegm.ErrorView, "error.json", errors: ["Must be a member of the group"])
      member ->
        cond do
          member.role == "admin" ->
            case {type, params} do
              {"events", params} ->
                case Repo.get(Thegm.GroupEvents, events_id) do
                  nil ->
                    conn
                    |> put_status(:not_found)
                    |> render(Thegm.ErrorView, "error.json", errors: ["No event with that id found"])
                  event ->
                    case read_start_end(params) do
                      {:ok, settings} ->
                        params = Map.put(params, "start_time", settings.start_time)
                        params = Map.put(params, "end_time", settings.end_time)
                        params = Map.put(params, "groups_id", groups_id)
                        event_changeset = GroupEvents.update_changeset(event, params)

                        case Repo.update(event_changeset) do
                          {:ok, event} ->
                            event = event |> Repo.preload([:groups, :games])
                            conn
                            |> put_status(:created)
                            |> render("show.json", event: event)
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
end
