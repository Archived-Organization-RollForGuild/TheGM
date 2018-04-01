defmodule Thegm.GroupEventsView do
  use Thegm.Web, :view

  def render("show.json", %{event: event, is_member: is_member}) do
    cond do
      is_member ->
        %{
          data: private_show(event),
          included: [hydrate_group(event.groups), hydrate_game(event.games)]
        }
      true ->
        %{
          data: public_show(event),
          included: [hydrate_group(event.groups), hydrate_game(event.games)]
        }
    end
  end

  def private_show(event) do
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

  def public_show(event) do
    %{
      id: event.id,
      type: "events",
      attributes: %{
        title: event.title,
        description: event.description,
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

  def relationship_link(group) do
    %{link: Application.get_env(:thegm, :api_url) <> "/groups/" <> group.id <> "/events"}
  end
end
