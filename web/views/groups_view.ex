defmodule Thegm.GroupsView do
  use Thegm.Web, :view

  def render("memberof.json", %{group: group}) do
    %{data: full_json(group)}
  end

  def render("notmember.json", %{group: group}) do
    %{data: non_member_json(group)}
  end

  def full_json(group) do
    %{type: "group", attributes: %{name: group.name, address: %{street1: group.street1, street2: group.street2, city: group.city, state: group.state, country: group.country, zip: group.zip}, geo: %{lat: elem(group.geog.coordinates, 1), lon: elem(group.geog.coordinates, 0)}, contact: %{email: group.email, phone: group.phone}, games: group.games}, relationships: relationships(group.id)}
  end

  def relationships(group_id) do
    base = Application.get_env(:thegm, :api_url)
    %{members: %{links: %{related: base <> "/groups/" <> group_id <> "/members"}}}
  end

  def non_member_json(group) do
    %{type: "group", attributes: %{name: group.name, games: group.games}}
  end
end
