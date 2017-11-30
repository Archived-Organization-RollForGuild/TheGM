defmodule Thegm.RollDiceView do
  use Thegm.Web, :view

  # show dice
  def render("index.json", %{dice: dice}) do
    %{
        meta: %{count: length(dice)},
        data: Enum.map(dice, &dice_json/1)
    }
  end

  def dice_json(die) do
    %{
        type: die.type,
        count: die.count,
        rolls: die.rolls
    }
  end
end
