defmodule Thegm.Games do
  use Thegm.Web, :model
  alias Thegm.Validators

  @uuid_namespace UUID.uuid5(:url, "https://rollforguild.com/games/")

  @primary_key {:id, :binary_id, autogenerate: false}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "games" do
    field :name, :string, null: false
    field :version, :string, null: true
    field :description, :string, null: true
    field :publisher, :string, null: true
    field :url, :string, null: true
    field :avatar, :boolean, null: false
    has_many :user_games, Thegm.UserGames
    has_many :group_games, Thegm.GroupGames

    timestamps()
  end

  def generate_uuid(name, version \\ "") do
    UUID.uuid5(@uuid_namespace, name <> "/" <> version)
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:name, :description, :version, :avatar, :url, :publisher])
    |> validate_required([:name], message: "Are required")
    |> validate_length(:version, min: 1, message: "Game version can not be empty")
    |> validate_length(:publisher, min: 1, message: "Game publisher can not be empty")
    |> validate_length(:description, max: 500, message: "Game description can be no more than 500 characters.")
    |> validate_length(:name, min: 1, max: 200)
    |> Validators.validate_url(:url)
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> changeset(params)
    |> cast(%{
      id: generate_uuid(params["name"], params["version"]), avatar: false}, [:id, :avatar])
  end
end
