defmodule Thegm.Preferences do
  @moduledoc """
    Database model for user preferences
  """
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "preferences" do
    field :timezone, :integer, null: true
    belongs_to :users, Thegm.Users

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:user_id])
    |> changeset(params)
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:timezone])
  end
end
