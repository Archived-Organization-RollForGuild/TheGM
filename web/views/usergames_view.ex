defmodule Thegm.UserGamesView do
  use Thegm.Web, :view

  def render("index.json", %{usergames: usergames}) do
    %{data: Enum.map(usergames, &usergame/1)}
  end

  def usergame(usergame) do
    base = Application.get_env(:thegm, :api_url)
    %{
      type: "user-games",
      id: usergame.id,
      attributes: %{
        games_id: usergame.games_id,
        users_id: usergame.users_id
      },
      relationships: %{
        game: %{
          links: %{
            self: base <> "/games/" <> usergame.games_id
          }
        },
        user: %{
          links: %{
            self: base <> "/users/" <> usergame.users_id
          }
        }
      }
    }
  end

  def users_games(user_games) do
    %{
      data: Enum.map(user_games, fn(x) -> Thegm.GamesView.relationship_data(x.games) end)
    }
  end
end
