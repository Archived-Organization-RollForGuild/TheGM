defmodule Thegm.GamesView do
  use Thegm.Web, :view

  def render("show.json", %{game: game}) do
    %{
      data: games_show(game)
    }
  end

  #show multiple users
  def render("index.json", %{games: games, meta: meta}) do
    data = Enum.map(games, &games_show/1)

    %{meta: search_meta(meta), data: data}
  end

  def games_show(game) do
    %{
      type: "games",
      id: game.id,
      attributes: %{
        avatar: game.avatar,
        description: game.description,
        name: game.name,
        version: game.version,
        publisher: game.publisher,
        url: game.url
      },
      relationships: %{}
    }
  end

  def relationship_data(game) do
    %{
      id: game.id,
      type: "games"
    }
  end

  def search_meta(meta) do
    %{total: meta.total, count: meta.count, limit: meta.limit, offset: meta.offset}
  end

  def users_usergames_games(game) do
    games_show(game)
  end
end
