defmodule Thegm.GroupGamesController do
  use Thegm.Web, :controller

  alias Thegm.GroupGames

  def index(conn, params = %{"groups_id" => groups_id}) do
    with {:ok, settings} <- Thegm.ReadPagination.read_pagination_params(params),
      total when not is_nil(total) <- Repo.one(
        from gg in GroupGames,
        where: gg.groups_id == ^groups_id,
        select: count(gg.id)
      ),
      games when is_list(games) <- Repo.all(
        from gg in GroupGames,
        where: gg.groups_id == ^groups_id,
        limit: ^settings.limit,
        offset: ^settings.offset,
        preload: [:games, :game_suggestions]
      ) do
        meta = %{total: total, limit: settings.limit, offset: settings.offset, count: length(games)}

        conn
        |> put_status(:ok)
        |> render("index.json", group_games: games, meta: meta)
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
