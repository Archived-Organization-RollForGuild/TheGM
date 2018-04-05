defmodule Thegm.UserGamesView do
  use Thegm.Web, :view

  def render("index.json", %{usergames: usergames, meta: meta}) do
    %{
      meta: Thegm.MetaView.meta(meta),
      data: Enum.map(usergames, &hydrate_user_game/1)
    }
  end

  def hydrate_user_game(usergame) do
    usergame_hydration = %{
      type: "user-games",
      id: usergame.games_id,
      attributes: Thegm.GamesView.games_show(usergame.games)
    }
    usergame_hydration = put_in(usergame_hydration, [:attributes, :field], usergame.field)
    put_in(usergame_hydration, [:attributes, :inserted_at], usergame.inserted_at)
  end

  def users_games(user_games) do
    %{
      data: Enum.map(user_games, fn(x) -> Thegm.GamesView.relationship_data(x.games) end)
    }
  end
end
