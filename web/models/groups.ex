defmodule Thegm.Groups do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "groups" do
    field :name, :string
    field :description, :string
    field :address, :string, null: false
    field :games, {:array, :string}
    field :distance, :float, virtual: true
    field :geom, Geo.Geometry
    field :discoverable, :boolean
    has_many :group_members, Thegm.GroupMembers

    timestamps()
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:name, :description, :street1, :street2, :city, :state, :country, :zip, :games, :discoverable])
    |> validate_required([:name, :address, :discoverable], message: "Are required")
    |> unique_constraint(:name, message: "Group name must be unique")
    |> validate_length(:address, min: 1, message: "Group address can not be empty")
    |> validate_length(:description, max: 1000, message: "Group description can be no more than 1000 characters.")
    |> validate_format(:name, ~r/^[a-zA-Z0-9\s'_-]+$/, message: "Group name must be alpha numeric (and may include  -, ')")
    |> validate_length(:name, min: 1, max: 200)
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> changeset(params)
    |> lat_lon
  end

  def lat_lon(model) do
    case GoogleMaps.geocode(model.changes.address) do
      {:ok, result} ->
        lat = List.first(result["results"])["geometry"]["location"]["lat"]
        lon = List.first(result["results"])["geometry"]["location"]["lng"]
        model
        |> put_change(:geom, %Geo.Point{coordinates: {lon, lat}, srid: 4326})
    end
  end
end
