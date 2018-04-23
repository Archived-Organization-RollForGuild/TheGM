defmodule Thegm.GamesController do
  use Thegm.Web, :controller
  alias Thegm.Games

  def index(conn, params) do
    case Thegm.ReadPagination.read_pagination_params(params) do
      {:ok, settings} ->
        # Get total in search
        query = params["query"] <> "%"
        total = Repo.one(
                  from g in Games,
                  left_join: gd in assoc(g, :game_disambiguations),
                  select: count(fragment("DISTINCT ?", g.id)),
                  where: ilike(g.name, ^query) or ilike(gd.name, ^query)
        )

        # do the search
        games = Repo.all(
                    from g in Games,
                    left_join: gd in assoc(g, :game_disambiguations),
                    where: ilike(g.name, ^query) or ilike(gd.name, ^query),
                    group_by: g.id,
                    limit: ^settings.limit,
                    offset: ^settings.offset
                  )

        meta = %{total: total, limit: settings.limit, offset: settings.offset, count: length(games)}

        conn
        |> put_status(:ok)
        |> render("index.json", games: games, meta: meta)
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
        |> halt()
    end
  end

  def show(conn, %{"id" => games_id}) do
    case Repo.get(Games, games_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["No game with that id found"])
        |> halt()
      game ->
        conn
        |> put_status(:ok)
        |> render("show.json", game: game)
    end
  end
end
