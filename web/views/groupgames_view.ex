defmodule Thegm.GroupGamesView do
  use Thegm.Web, :view

  def render("index.json", %{group_games: group_games, meta: meta}) do
    data = Enum.map(group_games, &show/1)

    %{
      meta: Thegm.MetaView.meta(meta),
      data: data
    }
  end

  def show(group_game) do
    cond do
      group_game.games_id != nil ->
        Thegm.GamesView.games_show(group_game.games)

      group_game.game_suggestions_id != nil ->
        Thegm.GameSuggestionsView.game_suggestion_show(group_game.game_suggestions)

      true ->
        # Should hopefully never occur
        {}
    end
  end

  def relationship_link(group) do
    %{
      link: Application.get_env(:thegm, :api_url) <> "/groups/" <> group.id <> "/games"
    }
  end
end
# credo:disable-for-this-file
