defmodule Thegm.GeoView do
  use Thegm.Web, :view

  def geo(geo) do
    unless geo == nil do
      %{lat: elem(geo.coordinates, 1), lng: elem(geo.coordinates, 0)}
    else
        nil
    end
  end
end
# credo:disable-for-this-file
