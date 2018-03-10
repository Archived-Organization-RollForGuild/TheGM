defmodule Thegm.ThreadsController do
  use Thegm.Web, :controller

  alias Thegm.Users
  alias Thegm.Threads

  def create(conn, %{"data" => %{"attributes" => params, "type" => type}}) do
    users_id = conn.assigns[:current_user].id
    case {type, params} do
      {"threads", params} ->
        thread_changeset = Threads.create_changeset(%Threads{}, Map.merge(params, %{"users_id" => users_id}))
        case Repo.insert(thread_changeset) do
          {:ok, thread} ->
            thread = thread |> Repo.preload(:users)
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
