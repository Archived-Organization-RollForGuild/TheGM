defmodule Thegm.MessageThreads do
  @moduledoc "Database model for threads of direct messages"
  @keyphrase Base.url_decode64!(System.get_env("RFG_API_ENCRYPTION_KEYPHRASE") || "")

  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "message_threads" do
    field :title_encrypted, :binary
    field :iv, :binary
    field :title, :string, virtual: true
    has_many :message_participants, Thegm.MessageParticipants

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:title])
    |> encrypt_thread_title
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:title])
    |> encrypt_thread_title
  end

  defp encrypt_thread_title(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{title: title}} ->
        {:ok, {iv, encrypted_title}} = ExCrypto.encrypt(@keyphrase, title)
        changeset = put_change(changeset, :title_encrypted, encrypted_title)
        put_change(changeset, :iv, iv)
      _ ->
        changeset
    end
  end

  def get_thread_title(model) do
    if model.title_encrypted do
      {:ok, title} = ExCrypto.decrypt(@keyphrase, model.iv, model.title_encrypted)
      title
    else
      nil
    end
  end
end
