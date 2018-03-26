defmodule Thegm.GroupThreadCommentsController do
  use Thegm.Web, :controller

  alias Thegm.GroupThreadComments

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
                comment = comment |> Repo.preload([:users, :group_threads, :groups])
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
                ) |> Repo.preload([:users, :group_threads, :groups])

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

  def delete(conn, %{"groups_id" => _, "threads_id" => _, "id" => comments_id}) do
    current_user_id = conn.assigns[:current_user].id

    case Repo.get(GroupThreadComments, comments_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Comment not found, maybe you already deleted it?"])
      comment ->
        cond do
          comment.users_id == current_user_id ->
            case Repo.update(GroupThreadComments.soft_delete(comment)) do
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
