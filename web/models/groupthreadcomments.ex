defmodule Thegm.GroupThreadComments do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "thread_comments" do
    field :comment, :string
    belongs_to :group_threads, Thegm.GroupThreads
    belongs_to :groups, Thegm.Groups
    belongs_to :users, Thegm.Users

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:comment, :group_threads_id, :users_id, :groups_id])
    |> validate_required([:comment, :users_id, :group_threads_id, :groups_id], message: "are required")
    |> validate_length(:comment, min: 1, max: 8192, message: "must be between 1 and 8192 characters, inclusive")
  end
end
