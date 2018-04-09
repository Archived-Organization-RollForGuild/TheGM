defmodule Thegm.GroupGames do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "group_games" do
    belongs_to :groups, Thegm.Groups
    belongs_to :games, Thegm.Games

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:games_id, :groups_id])
    |> validate_required([:groups_id, :games_id])
    |> unique_constraint(:groups_id, name: :group_games_games_id_groups_id_index)
    |> foreign_key_constraint(:games_id, name: :group_games_games_id_fk)
  end
end
# credo:disable-for-this-file
