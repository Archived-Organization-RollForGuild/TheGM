defmodule Thegm.GameSuggestions do
  use Thegm.Web, :model

  @moduledoc """
  Model and changesets for game_suggestions table
  """

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "game_suggestions" do
    field :name, :string
    field :version, :string
    field :publisher, :string
    field :url, :string
    field :status, :string
    belongs_to :users, Thegm.Users
    belongs_to :groups, Thegm.Groups

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    params = Map.merge(params, %{"status" => "pending"})
    model
    |> cast(params, [:name, :version, :publisher, :url, :users_id, :groups_id, :status])
    |> validate_required([:name, :users_id], message: "are required")
    |> validate_length(:name, min: 1, max: 8192, message: "must be between 1 and 8192 characters")
    |> validate_length(:version, max: 8192, message: "must be less than 8192 characters")
    |> validate_length(:publisher, max: 8192, message: "must be less than 8192 characters")
    |> validate_length(:url, max: 8192, message: "must be less than 8192 characters")
  end
end
