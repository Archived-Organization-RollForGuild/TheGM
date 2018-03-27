defmodule Thegm.GroupGamesView do
  use Thegm.Web, :view

  def groups_games(group_games) do
    %{
      data: Enum.map(group_games, fn(x) -> Thegm.GamesView.relationship_data(x.games) end)
    }
  end
end
