defmodule Thegm.RollDiceController do
  use Thegm.Web, :controller

  alias Thegm.RollDice

  def index(conn, %{"dice" => dice}) do
    result_dice = eat_dice(dice)

    conn
    |> put_status(:ok)
    render conn, "index.json", dice: result_dice
  end

  def eat_dice([]) do
    []
  end

  def eat_dice([head | tail]) do
    split = String.split(head, "d", parts: 2)
    {number, _rem} = Integer.parse(Enum.at(split, 0))
    {sides, _rem} = Integer.parse(Enum.at(split, 1))
    results = for n <- 1..number, do: :rand.uniform(sides)
    short = %{:type => "d" <> Enum.at(split, 1), :count => number, :rolls => results}
    result_dice = [short | eat_dice(tail)]
    result_dice
  end

end
