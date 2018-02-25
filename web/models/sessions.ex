defmodule Thegm.Sessions do
  @moduledoc "Database model for user sessions"

  use Thegm.Web, :model

  @foreign_key_type :binary_id
  schema "sessions" do
    field :token, :string
    belongs_to :user, Thegm.Users

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:token, :user_id])
    |> validate_required([:user_id])
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> changeset(params)
    |> put_change(:token, SecureRandom.urlsafe_base64())
  end
end
