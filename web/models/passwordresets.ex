defmodule Thegm.PasswordResets do
  @moduledoc "Database model for password reset requests"

  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "password_resets" do
    field :used, :boolean
    belongs_to :user, Thegm.Users

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `user_id`.
  """

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:used, :user_id])
  end
end
