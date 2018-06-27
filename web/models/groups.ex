defmodule Thegm.Groups do
  use Thegm.Web, :model
  alias Thegm.Repo
  import Ecto.Query
  import Geo.PostGIS
  @uuid_namespace UUID.uuid5(:url, "https://rollforguild.com/groups/")

  @primary_key {:id, :binary_id, autogenerate: false}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "groups" do
    field :name, :string
    field :slug, :string, null: false
    field :description, :string
    field :address, :string, null: true
    field :distance, :float, virtual: true
    field :geom, Geo.Geometry
    field :discoverable, :boolean
    field :member_status, :string, virtual: true
    has_many :group_members, Thegm.GroupMembers
    has_many :join_requests, Thegm.GroupJoinRequests
    has_many :blocked_users, Thegm.GroupBlockedUsers
    has_many :group_games, Thegm.GroupGames
    has_many :group_events, Thegm.GroupEvents


    timestamps()
  end

  def generate_uuid(resource) do
    UUID.uuid5(@uuid_namespace, resource)
  end

  def set_member_status(model, status) do
    model
    |> put_change(:member_status, status)
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:name, :description, :address, :discoverable])
    |> validate_required([:name, :discoverable], message: "Are required")
    |> validate_length(:address, min: 1, message: "Group address can not be empty")
    |> validate_length(:description, max: 1000, message: "Group description can be no more than 1000 characters.")
    |> validate_length(:name, min: 1, max: 200)
    |> lat_lng(params)
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> changeset(params)
    |> lat_lng(params)
    |> cast(%{id: generate_uuid(params["slug"])}, [:id])
    |> cast(params, [:slug])
    |> unique_constraint(:slug, message: "Group slug must be unique")
    |> validate_required([:slug], message: "Are required")
    |> validate_format(:slug, ~r/^[a-zA-Z0-9\s-]+$/, message: "Group slug must be alpha numeric (and may include  -)")
  end

  def lat_lng(model, params) do
    cond do
      Map.has_key?(params, "lat") && Map.has_key?(params, "lng") ->
        model
        |> put_change(:geom, %Geo.Point{coordinates: {params["lng"], params["lat"]}, srid: 4326})
      Map.has_key?(params, "address") ->
        model
        |> put_change(:geom, nil)

      true ->
        model
    end
  end

  def get_total_groups_with_settings(settings, geom, memberships, blocked_by) do
    total = Repo.one(from g in Thegm.Groups,
      select: count(g.id),
      where: st_distancesphere(g.geom, ^geom) <= ^settings.meters and not g.id in ^memberships and not g.id in ^blocked_by and g.discoverable == true)
    {:ok, total}
  end

  def get_group_by_id_with_games(groups_id) do
    case Repo.one(from g in Thegm.Groups, where: g.id == ^groups_id, preload: :group_games) do
      nil ->
        {:error, :not_found, "could not find group with specified `id`"}
      group ->
        {:ok, group}
    end
  end

  def get_groups_with_settings(users_id, settings, geom, memberships, blocked_by, offset) do
    join_requests_query = case users_id do
      nil ->
        from gjr in Thegm.GroupJoinRequests, where: is_nil(gjr.users_id), order_by: [desc: gjr.inserted_at]
      _ ->
        from gjr in Thegm.GroupJoinRequests, where: gjr.users_id == ^users_id, order_by: [desc: gjr.inserted_at]
    end

    groups = Repo.all(
      from g in Thegm.Groups,
      select: %{g | distance: st_distancesphere(g.geom, ^geom)},
      where: st_distancesphere(g.geom, ^geom) <= ^settings.meters and not g.id in ^memberships and not g.id in ^blocked_by and g.discoverable == true,
      order_by: [asc: st_distancesphere(g.geom, ^geom)],
      limit: ^settings.limit,
      offset: ^offset
    ) |> Repo.preload([join_requests: join_requests_query, group_members: :users, group_games: :games])

    {:ok, groups}
  end

  def get_group_by_id!(groups_id) do
    group = Repo.one(from g in Thegm.Groups, where: (g.id == ^groups_id))
    if group == nil do
      {:error, :not_found, "A group with the specified `id` was not found"}
    else
      {:ok, group}
    end
  end

  def preload_join_requests_by_requestee_id(group, nil), do: {:ok, group}
  def preload_join_requests_by_requestee_id(group, users_id) do
    join_requests_query = from gjr in Thegm.GroupJoinRequests, where: gjr.users_id == ^users_id, order_by: [desc: gjr.inserted_at]
    group = group|> Repo.preload([join_requests: join_requests_query, group_members: :users, group_games: :games])
    {:ok, group}
  end
end
# credo:disable-for-this-file
