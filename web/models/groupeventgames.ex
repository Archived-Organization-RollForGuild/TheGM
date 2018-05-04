defmodule Thegm.GroupEventGames do
  use Thegm.Web, :model

  @moduledoc """
  Model and changesets for group_event_games table
  """

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "group_event_games" do
    belongs_to :group_events, Thegm.GroupEvents
    belongs_to :games, Thegm.Games
    belongs_to :game_suggestions, Thegm.GameSuggestions

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:group_events_id, :games_id, :game_suggestions_id])
    |> validate_required([:group_events_id], message: "is required")
    |> check_constraint(:games_id, name: :exactly_one, message: "May only supply a games_id or game_suggestions_id, but not both!")
  end
end
