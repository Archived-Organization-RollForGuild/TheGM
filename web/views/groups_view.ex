defmodule Thegm.GroupsView do
  use Thegm.Web, :view

  def render("memberof.json", %{group: group}) do
    %{data: full_json(group)}
  end

  def full_json(group) do
    %{type: "group", attributes: %{name: group.name, address: %{street1: group.street1, street2: group.street2, city: group.city, state: group.state, country: group.country, zip: group.zip}, geo: %{lat: group.lat, lon: group.lon}, contact: %{email: group.email, phone: group.phone}, games: group.games}}
  end
end
