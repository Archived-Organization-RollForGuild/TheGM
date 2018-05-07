defmodule Thegm.GroupThreadCommentsController do
  use Thegm.Web, :controller

  alias Thegm.GroupThreadComments
  alias Ecto.Multi

  def create(conn, %{"groups_id" => groups_id, "group_threads_id" => group_threads_id, "data" => %{"attributes" => params, "type" => type}}) do
    users_id = conn.assigns[:current_user].id
    case Repo.one(from gm in Thegm.GroupMembers, where: gm.groups_id == ^groups_id and gm.users_id == ^users_id) do
      nil ->
        conn
        |> put_status(:forbidden)
        |> render(Thegm.ErrorView, "error.json", errors: ["Must be a membere of group"])
      _ ->
        case {type, params} do
          {"thread-comments", params} ->
            comment_changeset = GroupThreadComments.create_changeset(%GroupThreadComments{}, Map.merge(params, %{"users_id" => users_id, "group_threads_id" => group_threads_id, "groups_id" => groups_id}))
            case Repo.insert(comment_changeset) do
              {:ok, comment} ->
                comment = comment |> Repo.preload([:users, :group_threads, :groups, :group_thread_comments_deleted])
                conn
                |> put_status(:created)
                |> render("create.json", comment: comment)
              {:error, resp} ->
                error_list = Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end)
                conn
                |> put_status(:bad_request)
                |> render(Thegm.ErrorView, "error.json", errors: error_list)
            end
            _ ->
              conn
              |> put_status(:bad_request)
              |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `thread-comments` data type"])
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
            total = Repo.one(from gtc in GroupThreadComments, where: gtc.group_threads_id == ^settings.group_threads_id and gtc.groups_id == ^settings.groups_id, select: count(gtc.id))

            # calculate offset
            offset = (settings.page - 1) * settings.limit

            # do the search
            cond do
              total > 0 ->
                comments = Repo.all(
                  from gtc in GroupThreadComments,
                  where: gtc.group_threads_id == ^settings.group_threads_id and gtc.groups_id == ^settings.groups_id,
                  order_by: [asc: :inserted_at],
                  limit: ^settings.limit,
                  offset: ^offset
                ) |> Repo.preload([:users, :group_threads, :groups, :group_thread_comments_deleted])

                meta = %{total: total, limit: settings.limit, offset: offset, count: length(comments)}

                conn
                |> put_status(:ok)
                |> render("index.json", comments: comments, meta: meta)
              true ->
                meta = %{total: total, limit: settings.limit, offset: offset, count: 0}
                conn
                |> put_status(:ok)
                |> render("index.json", comments: [], meta: meta)
            end
        end
      {:error, errors} ->
        IO.inspect errors
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> v end))
    end
  end

  def show(conn, %{"groups_id" => groups_id, "group_threads_id" => threads_id, "id" => comments_id}) do
    users_id = conn.assigns[:current_user].id
    case Repo.one(from gm in Thegm.GroupMembers, where: gm.groups_id == ^groups_id and gm.users_id == ^users_id and gm.active == true) do
      nil ->
        conn
        |> put_status(:forbidden)
        |> render(Thegm.ErrorView, "error.json", errors: ["Must be a member of the group to take this action"])
      _ ->
        case Repo.one(from gtc in Thegm.GroupThreadComments, where: gtc.groups_id == ^groups_id and gtc.group_threads_id == ^threads_id and gtc.id == ^comments_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["A comment belonging to that group and thread was not found"])
          comment ->
            comment = comment |> Repo.preload([:groups, :group_threads, :users, :group_thread_comments_deleted])
            conn
            |> put_status(:ok)
            |> render("show.json", comment: comment)
        end
    end
  end

  def delete(conn, %{"groups_id" => groups_id, "group_threads_id" => threads_id, "id" => comments_id}) do
    users_id = conn.assigns[:current_user].id
    case Repo.one(from gm in Thegm.GroupMembers, where: gm.groups_id == ^groups_id and gm.users_id == ^users_id and gm.active == true) do
      nil ->
        conn
        |> put_status(:forbidden)
        |> render(Thegm.ErrorView, "error.json", errors: ["Must be a member of the group to take this action"])
      _ ->
        case Repo.one(from gtc in Thegm.GroupThreadComments, where: gtc.groups_id == ^groups_id and gtc.group_threads_id == ^threads_id and gtc.id == ^comments_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["A comment belonging to that group and thread was not found"])
          comment ->
            cond do
              comment.users_id == users_id ->
                delete_comment = GroupThreadComments.update_changeset(comment, %{deleted: true})
                deleted_info = Thegm.GroupThreadCommentsDeleted.create_changeset(%Thegm.GroupThreadCommentsDeleted{}, %{users_id: users_id, group_thread_comments_id: comment.id, deleter_role: "user"})
                multi =
                  Multi.new
                  |> Multi.update(:group_thread_comments, delete_comment)
                  |> Multi.insert(:group_thread_comments_deleted, deleted_info)

                  case Repo.transaction(multi) do
                    {:ok, %{group_thread_comments: updated_comment, group_thread_comments_deleted: _}} ->
                      updated_comment = updated_comment |> Repo.preload([:users, :groups, :group_threads, :group_thread_comments_deleted])
                      conn
                      |> put_status(:ok)
                      |> render("show.json", comment: updated_comment)
                    {:error, :group_thread_comments, changeset, %{}} ->
                      conn
                      |> put_status(:unprocessable_entity)
                      |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                    {:error, :group_thread_comments_deleted, changeset, %{}} ->
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

    # verify groups_id
    {group_threads_id, errors} = case params["group_threads_id"] do
      nil ->
        errors = errors ++ [threads_id: "Must be supplied"]
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
        {:ok, %{group_threads_id: group_threads_id, groups_id: groups_id, page: page, limit: limit}}
    end
    resp
  end
end
# credo:disable-for-this-file
