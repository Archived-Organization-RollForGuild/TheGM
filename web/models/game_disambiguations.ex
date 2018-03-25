defmodule Thegm.GameDisambiguations do
  use Thegm.Web, :model

  @uuid_namespace UUID.uuid5(:url, "https://rollforguild.com/gamedisambiguations/")

  @primary_key {:id, :binary_id, autogenerate: false}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "game_disambiguations" do
    field :name, :string, null: false
    belongs_to :games, Thegm.Games

    timestamps()
  end

  def generate_uuid(name) do
    UUID.uuid5(@uuid_namespace, name)
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:name])
    |> validate_required([:name], message: "Are required")
    |> validate_length(:name, min: 1, max: 200)
    |> Validators.validate_url(:url)
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> changeset(params)
    |> cast(%{id: generate_uuid(params["name"])}, [:id])
  end
end
