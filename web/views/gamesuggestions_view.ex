defmodule Thegm.GameSuggestionsView do
  use Thegm.Web, :view

  def render("show.json", %{game_suggestion: game_suggestion}) do
    %{
      data: game_suggestion_show(game_suggestion)
    }
  end

  def render("index.json", %{game_suggestions: game_suggestions, meta: meta}) do
    data = Enum.map(game_suggestions, &game_suggestion_show/1)

    %{meta: Thegm.MetaView.meta(meta), data: data}
  end

  def game_suggestion_show(game_suggestion) do
    %{
      type: "game-suggestions",
      id: game_suggestion.id,
      attributes: %{
        name: game_suggestion.name,
        version: game_suggestion.version,
        publisher: game_suggestion.version,
        url: game_suggestion.url,
        status: game_suggestion.status
      }
    }
  end
end
