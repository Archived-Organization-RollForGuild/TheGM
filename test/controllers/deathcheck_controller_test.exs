defmodule Thegm.DeathCheckControllerTest do
  use Thegm.ConnCase

  test "index/1 respond with text that the API is not dead", %{conn: conn} do

    response =
      conn
      |> get(death_check_path(conn, :index))
      |> json_response(200)

    expected = %{
      "data" => %{
        "type" => "message",
        "message" => "Successful saving throw!"
      }
    }

    assert response == expected
  end
end
