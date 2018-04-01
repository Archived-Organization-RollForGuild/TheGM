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

  def render("index.json", %{events: events, meta: meta, is_member: is_member}) do
    distinct_games = Thegm.GamesView.included_games(events, [])
    hydrated_group = case events do
      [] ->
        []
      [head | _] ->
        [hydrate_group(head.groups)]
    end

    data = cond do
      is_member ->
        Enum.map(events, fn e -> private_show(e) end)
      true ->
        Enum.map(events, fn e -> public_show(e) end)
    end

    %{
      meta: meta,
      data: data,
      included: Enum.map(distinct_games, &hydrate_game/1) ++ hydrated_group
    }
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
