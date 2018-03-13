defmodule Thegm.ThreadCommentsController do
  use Thegm.Web, :controller

  alias Thegm.Users
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
end
