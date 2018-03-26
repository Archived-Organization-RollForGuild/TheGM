defmodule Thegm.ThreadCommentsController do
  use Thegm.Web, :controller

  alias Thegm.ThreadComments
  alias Ecto.Multi

  def create(conn, %{"threads_id" => threads_id, "data" => %{"attributes" => params, "type" => type}}) do
    users_id = conn.assigns[:current_user].id
    case {type, params} do
      {"thread-comments", params} ->
        comment_changeset = ThreadComments.create_changeset(%ThreadComments{}, Map.merge(params, %{"users_id" => users_id, "threads_id" => threads_id}))
        case Repo.insert(comment_changeset) do
          {:ok, comment} ->
            comment = comment |> Repo.preload([:users, :threads, :thread_comments_deleted])
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

  def index(conn, params) do
    case read_search_params(params) do
      {:ok, settings} ->
        # Get total in search
        total = Repo.one(from tc in ThreadComments, where: tc.deleted == false, select: count(tc.id))

        # calculate offset
        offset = (settings.page - 1) * settings.limit

        # do the search
        cond do
          total > 0 ->
            comments = Repo.all(
              from tc in ThreadComments,
              where: tc.deleted == false,
              order_by: [asc: :inserted_at],
              limit: ^settings.limit,
              offset: ^offset
            ) |> Repo.preload([:users, :threads, :thread_comments_deleted])

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
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
    end
  end

  def show(conn, %{"threads_id" => threads_id, "id" => comments_id}) do
    case Repo.get(ThreadComments, comments_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", error: ["A comment with that id was not found"])
      comment ->
        cond do
          comment.threads_id != threads_id ->
            conn
            |> put_status(:bad_request)
            |> render(Thegm.ErrorView, "error.json", error: ["Invalid combination of thread id and comment id"])
          true ->
            comment = comment |> Repo.preload([:users, :threads, :thread_comments_deleted])
            conn
            |> put_status(:ok)
            |> render("show.json", comment: comment)
        end
    end
  end

  def delete(conn, %{"threads_id" => threads_id, "id" => comments_id}) do
    users_id = conn.assigns[:current_user].id
    case Repo.get(ThreadComments, comments_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", error: ["A comment with that id was not found"])
      comment ->
        cond do
          comment.threads_id != threads_id ->
            conn
            |> put_status(:bad_request)
            |> render(Thegm.ErrorView, "error.json", error: ["Invalid combination of thread id and comment id"])
          comment.users_id == users_id ->
            delete_comment = ThreadComments.update_changeset(comment, %{deleted: true})
            deleted_info = Thegm.ThreadCommentsDeleted.create_changeset(%Thegm.ThreadCommentsDeleted{}, %{users_id: users_id, thread_comments_id: comment.id, deleter_role: "user"})
            multi =
              Multi.new
              |> Multi.update(:thread_comments, delete_comment)
              |> Multi.insert(:thread_comments_deleted, deleted_info)

              case Repo.transaction(multi) do
                {:ok, %{thread_comments: updated_comment, thread_comments_deleted: _}} ->
                  updated_comment = updated_comment |> Repo.preload([:users, :threads, :thread_comments_deleted])
                  conn
                  |> put_status(:ok)
                  |> render("show.json", comment: updated_comment)
                {:error, :thread_comments, changeset, %{}} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                {:error, :thread_comments_deleted, changeset, %{}} ->
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

  defp read_search_params(params) do
    errors = []

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
        {:ok, %{page: page, limit: limit}}
    end
    resp
  end
end
