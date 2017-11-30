defmodule Thegm.RollDiceController do
  use Thegm.Web, :controller

  alias Thegm.RollDice

  def index(conn, %{"dice" => dice}) do
    result_dice = []
    Enum.each dice, fn die ->
      split = String.split(die, "d", parts: 2)
      {number, _rem} = Integer.parse(Enum.at(split, 0))
      {sides, _rem} = Integer.parse(Enum.at(split, 1))
      results = for n <- 1..number, do: :rand.uniform(sides)
      result_dice = result_dice ++ [%{:type => "d" <> Enum.at(split, 1), :count => number, :rolls => results}]
    end

    conn
    |> put_status(:ok)
    #|> render("index.json", dice: result_dice)
  end
end
