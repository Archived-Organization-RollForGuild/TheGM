defmodule Thegm.ThreadComments do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "thread_comments" do
    field :comment, :string
    field :deleted, :boolean
    belongs_to :threads, Thegm.Threads
    belongs_to :users, Thegm.Users
    has_one :thread_comments_deleted, Thegm.ThreadCommentsDeleted


    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:comment, :threads_id, :users_id])
    |> validate_required([:comment, :users_id, :threads_id], message: "are required")
    |> validate_length(:comment, min: 1, max: 8192, message: "must be between 1 and 8192 characters, inclusive")
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:comment, :deleted])
  end
end
# credo:disable-for-this-file
