defmodule Thegm.GroupsController do
  use Thegm.Web, :controller

  def create(conn, params) do

    case GoogleMaps.geocode("address") do
      {:ok, result} ->
        lat = List.first(result["results"])["geometry"]["location"]["lat"]
        lon = List.first(result["results"])["geometry"]["location"]["lon"]

    end
  end

  def delete(conn, params) do

  end
  
  def index(conn, params) do

  end

  def show(conn, params) do

  end

  def update(conn, params) do

  end
end
