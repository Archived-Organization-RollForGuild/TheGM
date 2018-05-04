defmodule Thegm.MessageParticipants do
  @moduledoc "Database model for participants of a message thread"
  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "message_participants" do
    field :status, :string
    field :silenced, :boolean
    belongs_to :users, Thegm.Users
    belongs_to :message_threads, Thegm.MessageThreads

    timestamps()
  end


  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:status, :silenced, :users_id, :message_threads_id])
    |> validate_required([:users_id, :message_threads_id])
    |> unique_constraint(:users_id, name: :message_participants_message_threads_id_users_id_index)
    |> foreign_key_constraint(:message_threads_id, name: :message_threads_id_fk)
  end
end
