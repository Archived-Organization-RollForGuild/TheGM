defmodule Thegm.GroupGamesView do
  use Thegm.Web, :view

  def render("index.json", %{groupgames: groupgames}) do
    %{data: Enum.map(groupgames, &groupgame/1)}
  end

  def groupgame(groupgame) do
    base = Application.get_env(:thegm, :api_url)
    %{
      type: "group-games",
      id: groupgame.id,
      attributes: %{
        games_id: groupgame.games_id,
        groups_id: groupgame.groups_id
      },
      relationships: %{
        game: %{
          links: %{
            self: base <> "/games/" <> groupgame.games_id
          }
        },
        group: %{
          links: %{
            self: base <> "/group/" <> groupgame.groups_id
          }
        }
      }
    }
  end

  def groups_games(group_games) do
    %{
      data: Enum.map(group_games, fn(x) -> Thegm.GamesView.relationship_data(x.games) end)
    }
  end
end
