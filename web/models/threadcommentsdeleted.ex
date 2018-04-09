defmodule Thegm.ThreadCommentsDeleted do
  use Thegm.Web, :model

  @primary_key false
  @foreign_key_type :binary_id

  schema "thread_comments_deleted" do
    field :deleter_role, :string
    belongs_to :thread_comments, Thegm.ThreadComments, primary_key: true
    belongs_to :users, Thegm.Users

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:users_id, :thread_comments_id, :deleter_role])
    |> validate_required([:users_id, :thread_comments_id, :deleter_role], messages: "are required")
  end
end
# credo:disable-for-this-file
