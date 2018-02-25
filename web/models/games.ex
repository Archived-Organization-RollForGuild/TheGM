defmodule Thegm.Games do
  @moduledoc "Database model for games"

  use Thegm.Web, :model
  @uuid_namespace UUID.uuid5(:url, "https://rollforguild.com/games/")

  @primary_key {:id, :binary_id, autogenerate: false}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "games" do
    field :name, :string
    field :description, :string
    field :version, :string
    field :avatar, :boolean


    timestamps()
  end

  def generate_uuid(name, version) do
    UUID.uuid5(@uuid_namespace, "#{name}/#{version}")
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:name, :description, :version, :avatar])
    |> validate_required([:name, :description, :version], message: "Are required")
    |> validate_format(:name, ~r/^[a-zA-Z0-9\s'_-]+$/, message: "Game name must be alpha numeric (and may include  -, ')")
    |> validate_length(:name, min: 1, max: 200)
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> changeset(params)
    |> cast(%{id: generate_uuid(params["name"], params["version"])}, [:id])
  end
end
