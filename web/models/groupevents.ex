defmodule Thegm.GroupEvents do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "group_events" do
    field :title, :string
    field :description, :string
    field :location, :string
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    belongs_to :groups, Thegm.Groups
    belongs_to :games, Thegm.Games

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:title, :description, :location, :start_time, :end_time, :groups_id, :games_id])
    |> validate_required([:title, :start_time, :end_time, :groups_id], message: "are required.")
    |> validate_length(:title, min: 1, max: 8192, message: "must be between 1 and 8192 characters.")
    |> validate_length(:description, max: 8192, message: "must be less than 8192 characters")
    |> validate_length(:location, max: 8192, message: "must be less than 8192 characters")
  end
end
