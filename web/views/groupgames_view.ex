defmodule Thegm.GroupGamesView do
  use Thegm.Web, :view

  def render("index.json", %{groupgames: groupgames, meta: meta}) do
    %{
      meta: Thegm.MetaView.meta(meta),
      data: Enum.map(groupgames, &hydrate_group_game/1)
    }
  end

  def hydrate_group_game(groupgame) do
    groupgame_hydration = %{
      type: "group-games",
      id: groupgame.games_id,
      attributes: Thegm.GamesView.games_show(groupgame.games)
    }
    put_in(groupgame_hydration, [:attributes, :inserted_at], groupgame.inserted_at)
  end

  def groups_games(group_games) do
    %{
      data: Enum.map(group_games, fn(x) -> Thegm.GamesView.relationship_data(x.games) end)
    }
  end
end
