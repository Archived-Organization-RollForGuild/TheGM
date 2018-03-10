defmodule Thegm.Threads do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "threads" do
    field :title, :string
    field :body, :string
    field :pinned, :boolean
    belongs_to :users, Thegm.Users

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:title, :body, :users_id])
    |> validate_required([:title, :users_id], message: "are required")
    |> validate_length(:title, min: 1, max: 256, message: "must be between 1 and 256 characters")
    |> validate_length(:body, max: 8192, message: "cannot exceed 8192 characters")
  end
end
