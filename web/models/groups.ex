defmodule Thegm.Groups do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "groups" do
    field :name, :string
    field :description, :string
    field :street1, :string
    field :street2, :string
    field :city, :string
    field :state, :string
    field :country, :string
    field :zip, :string
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
    |> validate_required([:name, :street1, :city, :state, :country, :zip, :discoverable], message: "Are required")
    |> unique_constraint(:name, message: "Group name must be unique")
    |> validate_length(:street1, min: 1, message: "Group street1 cannot be empty")
    |> validate_length(:city, min: 1, message: "Group city cannot be empty")
    |> validate_length(:state, min: 1, message: "Group state cannot be empty")
    |> validate_length(:country, min: 1, message: "Group country cannot be empty")
    |> validate_length(:zip, min: 1, message: "Group postal code cannot be empty")
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
    address = model.changes.street1
    address = cond do
      Map.has_key?(model.changes, :street2) ->
        address <> ", " <> model.changes.street2
      true -> address
    end
    address = address <> ", " <> model.changes.city <> ", " <> model.changes.state <> ", " <> model.changes.country <> ", " <> model.changes.zip
    case GoogleMaps.geocode(address) do
      {:ok, result} ->
        lat = List.first(result["results"])["geometry"]["location"]["lat"]
        lon = List.first(result["results"])["geometry"]["location"]["lng"]
        model
        |> put_change(:geom, %Geo.Point{coordinates: {lon, lat}, srid: 4326})
    end
  end
end
