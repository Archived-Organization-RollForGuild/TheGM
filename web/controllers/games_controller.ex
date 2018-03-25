defmodule Thegm.GamesController do
  use Thegm.Web, :controller

  def index(conn, params) do
    case read_search_params(params) do
      {:ok, settings} ->
        # Get total in search
        total = Repo.one(from t in Threads, select: count(t.id))

        # calculate offset
        offset = (settings.page - 1) * settings.limit

        # do the search
        cond do
          total > 0 ->
            threads = Repo.all(
                        from t in Threads,
                        order_by: [desc: :pinned, desc: :inserted_at],
                        limit: ^settings.limit,
                        offset: ^offset
                      ) |> Repo.preload([:users, :thread_comments])

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
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
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