defmodule Thegm.GroupThreadsController do
  use Thegm.Web, :controller

  alias Thegm.GroupThreads
  alias Ecto.Multi

  def create(conn, %{"groups_id" => groups_id, "data" => %{"attributes" => params, "type" => type}}) do
    users_id = conn.assigns[:current_user].id
    case Repo.one(from gm in Thegm.GroupMembers, where: gm.groups_id == ^groups_id and gm.users_id == ^users_id) do
      nil ->
        conn
        |> put_status(:forbidden)
        |> render(Thegm.ErrorView, "error.json", errors: ["Must be a membere of group"])
      _ ->
        case {type, params} do
          {"threads", params} ->
            thread_changeset = GroupThreads.create_changeset(%GroupThreads{}, Map.merge(params, %{"groups_id" => groups_id, "users_id" => users_id}))
            case Repo.insert(thread_changeset) do
              {:ok, thread} ->
                thread = thread |> Repo.preload([:users, :groups, :group_thread_comments, :group_threads_deleted])
                conn
                |> put_status(:created)
                |> render("show.json", thread: thread)
              {:error, resp} ->
                error_list = Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end)
                conn
                |> put_status(:bad_request)
                |> render(Thegm.ErrorView, "error.json", errors: error_list)
            end
          _ ->
            conn
            |> put_status(:bad_request)
            |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `threads` data type"])
        end
    end
  end

  def index(conn, params) do
    users_id = conn.assigns[:current_user].id
    case read_search_params(params) do
      {:ok, settings} ->
        case Repo.one(from gm in Thegm.GroupMembers, where: gm.groups_id == ^settings.groups_id and gm.users_id == ^users_id) do
          nil ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["Must be a membere of group"])
          _ ->
            # Get total in search
            total = Repo.one(from gt in GroupThreads, where: gt.groups_id == ^settings.groups_id and gt.deleted == false, select: count(gt.id))

            # calculate offset
            offset = (settings.page - 1) * settings.limit

            # do the search
            cond do
              total > 0 ->
                threads = Repo.all(
                  from gt in GroupThreads,
                  where: gt.groups_id == ^settings.groups_id and gt.deleted == false,
                  order_by: [desc: :pinned, desc: :inserted_at],
                  limit: ^settings.limit,
                  offset: ^offset
                ) |> Repo.preload([:users, :groups, :group_thread_comments, :group_threads_deleted, :group_threads_deleted])

                meta = %{total: total, limit: settings.limit, offset: offset, count: length(threads)}

                conn
                |> put_status(:ok)
                |> render("index.json", threads: threads, meta: meta)
              true ->
                meta = %{total: total, limit: settings.limit, offset: offset, count: 0}
                conn
                |> put_status(:ok)
                |> render("index.json", threads: [], meta: meta)
            end
        end
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
    end
  end

  def show(conn, %{"groups_id" => groups_id, "id" => threads_id}) do
    users_id = conn.assigns[:current_user].id
    case Repo.one(from gm in Thegm.GroupMembers, where: gm.groups_id == ^groups_id and gm.users_id == ^users_id) do
      nil ->
        conn
        |> put_status(:forbidden)
        |> render(Thegm.ErrorView, "error.json", errors: ["Must be a membere of group"])
      _ ->
        case Repo.get(GroupThreads, threads_id) |> Repo.preload([:users, :groups, :group_thread_comments, :group_threads_deleted]) do
          nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", error: ["A thread with that id belonging to the specified group was not found"])
          thread ->
            render conn, "show.json", thread: thread
        end
    end
  end

  def delete(conn, %{"groups_id" => groups_id, "id" => threads_id}) do
    users_id = conn.assigns[:current_user].id
    case Repo.one(from gm in Thegm.GroupMembers, where: gm.groups_id == ^groups_id and gm.users_id == ^users_id) do
      nil ->
        conn
        |> put_status(:forbidden)
        |> render(Thegm.ErrorView, "error.json", errors: ["Must be a membere of group"])
      _ ->
        case Repo.get(GroupThreads, threads_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", error: ["A thread with that id was not found"])
          thread ->
            cond do
              thread.users_id == users_id ->
                delete_thread = GroupThreads.update_changeset(thread, %{deleted: true})
                deleted_info = Thegm.GroupThreadsDeleted.create_changeset(%Thegm.GroupThreadsDeleted{}, %{users_id: users_id, group_threads_id: thread.id, deleter_role: "user"})
                multi =
                  Multi.new
                  |> Multi.update(:group_threads, delete_thread)
                  |> Multi.insert(:group_threads_deleted, deleted_info)

                  case Repo.transaction(multi) do
                    {:ok, %{group_threads: updated_thread, group_threads_deleted: _}} ->
                      updated_thread = updated_thread |> Repo.preload([:users, :groups, :group_thread_comments, :group_threads_deleted])
                      conn
                      |> put_status(:ok)
                      |> render("show.json", thread: updated_thread)
                    {:error, :group_threads, changeset, %{}} ->
                      conn
                      |> put_status(:unprocessable_entity)
                      |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                    {:error, :group_threads_deleted, changeset, %{}} ->
                      conn
                      |> put_status(:unprocessable_entity)
                      |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                  end
              true ->
                conn
                |> put_status(:forbidden)
                |> render(Thegm.ErrorView, "error.json", error: ["You must be the user who posted this thread to delete it"])
            end
        end
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
        {:ok, %{groups_id: groups_id, page: page, limit: limit}}
    end
    resp
  end
end
# credo:disable-for-this-file
