defmodule Thegm.GamesView do
  use Thegm.Web, :view

  def render("show.json", %{game: game}) do
    %{
      data: %{
        type: "games",
        id: game.id,
        attributes: games_show(game),
        relationships: %{}
      }
    }
  end

  #show multiple users
  def render("index.json", %{games: games}) do
    %{
      games: Enum.map(games, &games_show/1)
    }
  end

  def games_show(game) do
    %{
      avatar: game.avatar,
      description: game.description,
      name: game.name,
      version: game.version,
      publisher: game.publisher,
      url: game.url
    }
  end
end
