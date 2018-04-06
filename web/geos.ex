defmodule Thegm.Geos do

  def get_lat_lng(address) do
    case GoogleMaps.geocode(address) do
      {:ok, result} ->
        lat = List.first(result["results"])["geometry"]["location"]["lat"]
        lng = List.first(result["results"])["geometry"]["location"]["lng"]
        {:ok, %{lat: lat, lng: lng}}
      {:error, _} ->
        {:error, "Unable to locate lat/lng from address"}
    end
  end
end
