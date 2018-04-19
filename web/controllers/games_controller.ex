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

  def create(conn, %{"data" => %{"type" => type, "attributes" => params}}) do
    users_id = conn.assigns[:current_user].id
    if  type == "games" do
      game_changeset = Thegm.GameSuggestions.create_changeset(%Thegm.GameSuggestions{}, Map.merge(params, %{"users_id" => users_id}))
      case Repo.insert(game_changeset) do
        {:ok, game_suggestion} ->
          conn
          |> put_status(:created)
          |> render(Thegm.GameSuggestionsView, "show.json", game_suggestion: game_suggestion)

        {:error, resp} ->
          conn
          |> put_status(:bad_request)
          |> render(Thegm.ErrorView, "error.json", errors: Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
          |> halt()
      end
    else
      conn
      |> put_status(:bad_request)
      |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non 'games' type"])
      |> halt()
    end
  end
end
