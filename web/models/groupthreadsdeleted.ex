defmodule Thegm.GroupThreadsDeleted do
  use Thegm.Web, :model

  @primary_key false
  @foreign_key_type :binary_id

  schema "group_threads_deleted" do
    field :deleter_role, :string
    belongs_to :group_threads, Thegm.GroupThreads, primary_key: true
    belongs_to :users, Thegm.Users

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:users_id, :group_threads_id, :deleter_role])
    |> validate_required([:users_id, :group_threads_id, :deleter_role], message: "are required.")
  end
end
