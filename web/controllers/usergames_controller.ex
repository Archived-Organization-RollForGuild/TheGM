defmodule Thegm.UserGamesController do
  use Thegm.Web, :controller

  alias Thegm.UserGames

  def index(conn, params = %{"users_id" => users_id}) do
    with {:ok, settings} <- Thegm.Reader.read_pagination_params(params),
      total when not is_nil(total) <- Repo.one(
        from ug in UserGames,
        where: ug.users_id == ^users_id,
        select: count(ug.id)
      ),
      games when is_list(games) <- Repo.all(
        from ug in UserGames,
        where: ug.groups_id == ^users_id,
        limit: ^settings.limit,
        offset: ^settings.offset,
        preload: [:games, :game_suggestions]
      ) do
        meta = %{total: total, limit: settings.limit, offset: settings.offset, count: length(games)}

        conn
        |> put_status(:ok)
        |> render("index.json", user_games: games, meta: meta)
    else
      nil ->
        conn
        |> put_status(:internal_server_error)
        |> render(Thegm.ErrorView, "error.json", errors: ["Issue querying database"])
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn{k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
    end
  end
end
