defmodule Thegm.GeoView do
  @moduledoc "View for geo coordinates"

  use Thegm.Web, :view

  def geo(geo) do
    %{lat: elem(geo.coordinates, 1), lng: elem(geo.coordinates, 0)}
  end
end
