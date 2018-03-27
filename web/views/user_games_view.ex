defmodule Thegm.UserGamesView do
  use Thegm.Web, :view

  def users_games(user_games) do
    %{
      data: Enum.map(user_games, fn(x) -> Thegm.GamesView.relationship_data(x.games) end)
    }
  end
end
