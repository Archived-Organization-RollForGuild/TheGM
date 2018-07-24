defmodule Thegm.Users do
  @moduledoc false
  @uuid_namespace UUID.uuid5(:url, "https://rollforguild.com/users/")

  use Thegm.Web, :model

  alias Thegm.Repo

  @primary_key {:id, :binary_id, autogenerate: false}
  @derive {Phoenix.Param, key: :id}

  schema "users" do
    field :username, :string
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :active, :boolean
    field :avatar, :boolean
    field :bio, :string
    has_many :group_members, Thegm.GroupMembers
    has_many :user_games, Thegm.UserGames
    has_many :message_participants, Thegm.MessageParticipants
    has_one  :preferences, Thegm.Preferences

    timestamps()
  end

  def generate_uuid(resource_identifier) do
    UUID.uuid5(@uuid_namespace, resource_identifier)
  end

  # Parameters of the user that may be changed without special requirements like re-authentication or email validation
  def unrestricted_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:bio])
    |> validate_length(:bio, max: 500)
  end

  def update_password_changeset(model, params) do
    model
    |> cast(params, [:password])
    |> validate_required([:password], message: "Are required")
    |> validate_length(:password, min: 4)
    |> put_password_hash
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:username, :email, :active, :bio, :avatar])
    |> unique_constraint(:email, message: "Email is already taken")
    |> unique_constraint(:username, message: "Username is already taken")
    |> validate_format(:email, ~r/@/, message: "Invalid email address")
    |> validate_length(:email, min: 4, max: 255)
    |> validate_format(:username, ~r/^[a-zA-Z0-9\s'_-]+$/, message: "Username must be alpha numeric")
    |> validate_length(:username, min: 1, max: 200)
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> changeset(params)
    |> cast(%{id: generate_uuid(params["username"]), password: params["password"]}, [:id, :password])
    |> unique_constraint(:id, name: :users_pkey, message: "Username is already taken") #id is defined by username
    |> validate_required([:username, :password, :email], message: "Are required")
    |> validate_length(:password, min: 4)
    |> put_password_hash
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Comeonin.Argon2.hashpwsalt(password))
      _ ->
        changeset
    end
  end

  def get_user_by_id_with_groups_and_preferences(users_id) do
    case Repo.get(Thegm.Users, users_id) |> Repo.preload([{:group_members, :groups}, :preferences]) do
      nil ->
        {:error, :not_found, "A user with that id was not found"}
      user ->
        {:ok, user}
    end
  end

  def match_user_ids(users_id, current_users_id) do
    if users_id == current_users_id do
      {:ok, users_id}
    else
      {:error, :users_dont_match, "User id's do not match"}
    end
  end

  def get_user_by_id(users_id) do
    case Repo.get(Thegm.Users, users_id) do
      nil ->
        {:error, :not_found, "A user with that id was not found"}
      user ->
        {:ok, user}
    end
  end
end
