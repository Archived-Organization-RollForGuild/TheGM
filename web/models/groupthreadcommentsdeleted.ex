defmodule Thegm.GroupThreadCommentsDeleted do
  use Thegm.Web, :model

  @primary_key false
  @foreign_key_type :binary_id

  schema "group_thread_comments_deleted" do
    field :deleter_role, :string
    belongs_to :group_thread_comments, Thegm.GroupThreadComments, primary_key: true
    belongs_to :users, Thegm.Users

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:users_id, :group_thread_comments_id, :deleter_role])
    |> validate_required([:users_id, :group_thread_comments_id, :deleter_role])
  end
end
# credo:disable-for-this-file
