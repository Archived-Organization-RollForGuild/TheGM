defmodule Thegm.GroupEventGamesView do
  use Thegm.Web, :view

  def index("index.json", %{event_games: event_games, meta: meta}) do
    data = Enum.map(event_games, &show/1)

    %{
      meta: Thegm.MetaView.meta(meta),
      data: data
    }
  end

  def show(event_game) do
    cond do
      event_game.games_id != nil ->
        Thegm.GamesView.games_show(event_game.games)

      event_game.game_suggestions_id != nil ->
        Thegm.GameSuggestionsView.game_suggestion_show(event_game.game_suggestions)

      true ->
        # Should hopefully never occur
        {}
    end
  end

  def relationship_link(event) do
    %{
      link: Application.get_env(:thegm, :api_url) <> "/groups/" <> event.groups.id <> "/events/" <> event.id <> "/games"
    }
  end
end
