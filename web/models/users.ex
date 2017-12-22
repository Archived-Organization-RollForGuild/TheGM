defmodule Thegm.Users do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}

  schema "users" do
    field :username, :string
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :active, :boolean

    timestamps()
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:username, :email, :password])
    |> validate_required([:username, :password], message: "Are required")
    |> unique_constraint(:email, message: "Email is already taken")
    |> unique_constraint(:username, message: "Username is already taken")
    |> validate_format(:email, ~r/@/, message: "Invalid email address")
    |> validate_length(:email, min: 4, max: 255)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/, message: "Username must be alpha numeric")
    |> validate_length(:username, min: 1, max: 200)
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
end
