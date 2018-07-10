defmodule Thegm.UserGamesView do
  @moduledoc false
  use Thegm.Web, :view

  def render("index.json", %{group_games: group_games, meta: meta}) do
    data = Enum.map(group_games, &show/1)

    %{
      meta: Thegm.MetaView.meta(meta),
      data: data
    }
  end

  def show(user_game) do
    cond do
      user_game.games_id != nil ->
        Thegm.GamesView.games_show(user_game.games)

      user_game.game_suggestions_id != nil ->
        Thegm.GameSuggestionsView.game_suggestion_show(user_game.game_suggestions)

      true ->
        # Should hopefully never occur
        {}
    end
  end

  def relationship_link(user) do
    %{
      link: Application.get_env(:thegm, :api_url) <> "/users/" <> user.id <> "/games"
    }
  end
end
