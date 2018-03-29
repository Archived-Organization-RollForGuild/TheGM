defmodule Thegm.GroupEventsView do
  use Thegm.Web, :view

  def render("show.json", %{event: event}) do
    %{
      data: show(event),
      included: [hydrate_group(event.groups), hydrate_game(event.games)]
    }
  end

  def show(event) do
    %{
      id: event.id,
      type: "events",
      attributes: %{
        title: event.title,
        description: event.description,
        location: event.location,
        start_time: event.start_time,
        end_time: event.end_time
      },
      relationships: %{
        groups: Thegm.GroupsView.relationship_data(event.groups),
        games: Thegm.GamesView.relationship_data(event.games)
      }
    }
  end

  def hydrate_game(game) do
    %{
      id: game.id,
      type: "games",
      attributes: Thegm.GamesView.games_show(game)
    }
  end

  def hydrate_group(group) do
    %{
      id: group.id,
      type: "groups",
      attributes: Thegm.GroupsView.base_json(group)
    }
  end
end
