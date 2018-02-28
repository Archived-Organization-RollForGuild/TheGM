defmodule Thegm.GeoView do
  use Thegm.Web, :view

  def geo(geo) do
    %{lat: elem(geo.coordinates, 1), lng: elem(geo.coordinates, 0)}
  end
end
