defmodule Thegm.GameDisambiguations do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "game_disambiguations" do
    field :name, :string, null: false
    belongs_to :games, Thegm.Games

    timestamps()
  end


  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:name, :games_id])
    |> validate_required([:name], message: "Are required")
    |> validate_length(:name, min: 1, max: 200)
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> changeset(params)
  end
end
