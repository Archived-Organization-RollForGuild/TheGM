defmodule Thegm.ThreadCommentsController do
  use Thegm.Web, :controller

  alias Thegm.ThreadComments

  def create(conn, %{"threads_id" => threads_id, "data" => %{"attributes" => params, "type" => type}}) do
    users_id = conn.assigns[:current_user].id
    case {type, params} do
      {"thread-comments", params} ->
        comment_changeset = ThreadComments.create_changeset(%ThreadComments{}, Map.merge(params, %{"users_id" => users_id, "threads_id" => threads_id}))
        case Repo.insert(comment_changeset) do
          {:ok, comment} ->
            comment = comment |> Repo.preload([:users, :threads])
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
        total = Repo.one(from tc in ThreadComments, select: count(tc.id))

        # calculate offset
        offset = (settings.page - 1) * settings.limit

        # do the search
        cond do
          total > 0 ->
            comments = Repo.all(
              from tc in ThreadComments,
              order_by: [asc: :inserted_at],
              limit: ^settings.limit,
              offset: ^offset
            ) |> Repo.preload([:users, :threads])

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

  def delete(conn, %{"threads_id" => _, "id" => comments_id}) do
    current_user_id = conn.assigns[:current_user].id

    case Repo.get(ThreadComments, comments_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Comment not found, maybe you already deleted it?"])
      comment ->
        cond do
          comment.users_id == current_user_id ->
            case Repo.update(ThreadComments.soft_delete(comment)) do
              {:ok, _} ->
                send_resp(conn, :no_content, "")
              {:error, changeset} ->
                conn
                |> put_status(:internal_server_error)
                |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
            end
          true ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["You do not have permission delete this comment"])
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
