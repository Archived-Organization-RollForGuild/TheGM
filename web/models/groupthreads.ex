defmodule Thegm.GroupThreads do
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "group_threads" do
    field :title, :string
    field :body, :string
    field :pinned, :boolean
    field :deleted, :boolean
    belongs_to :users, Thegm.Users
    belongs_to :groups, Thegm.Groups
    has_one :group_threads_deleted, Thegm.GroupThreadsDeleted
    has_many :group_thread_comments, Thegm.GroupThreadComments

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:title, :body, :users_id, :groups_id])
    |> validate_required([:title, :users_id, :groups_id], message: "are required")
    |> validate_length(:title, min: 1, max: 256, message: "must be between 1 and 256 characters")
    |> validate_length(:body, max: 8192, message: "cannot exceed 8192 characters")
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:body, :pinned, :deleted])
  end

  def create_new_thread_notifications(groups_id, thread, user) do
    with {:ok, group} <- Thegm.Groups.get_group_by_id!(groups_id),
      {:ok, recipients} <- Thegm.GroupMembers.get_group_member_ids(groups_id, [user.id]) do
        type = "group::new-forum-thread"
        body = "#{user.username} created a new forum thread in #{group.name} entitled #{thread.title}"
        resources = [
          %{resources_type: "groups", resources_id: groups_id},
          %{resources_type: "threads", resources_id: thread.id},
          %{resources_type: "users", resources_id: user.id}
        ]
        Thegm.Notifications.create_notifications(body, type, recipients, resources)
    end
  end
end
# credo:disable-for-this-file
