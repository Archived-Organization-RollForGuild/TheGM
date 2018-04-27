defmodule Thegm.Messages do
  @moduledoc "Database model for direct messages"
  @keyphrase Base.url_decode64!(System.get_env("RFG_API_ENCRYPTION_KEYPHRASE") || "")

  use Thegm.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "messages" do
    field :body_encrypted, :binary
    field :iv, :binary
    field :body, :string, virtual: true
    belongs_to :message_threads, Thegm.MessageThreads
    belongs_to :users, Thegm.Users

    timestamps()
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:body, :users_id, :message_threads_id])
    |> encrypt_message_body
  end

  def new_message(model, params, users_id, message_threads_id) do
    model
    |> cast(params, [:body])
    |> put_change(:users_id, users_id)
    |> put_change(:message_threads_id, message_threads_id)
    |> encrypt_message_body
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, [:body])
    |> encrypt_message_body
  end

  defp encrypt_message_body(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{body: body}} ->
        {:ok, {iv, encrypted_body}} = ExCrypto.encrypt(@keyphrase, body)
        changeset = put_change(changeset, :body_encrypted, encrypted_body)
        put_change(changeset, :iv, iv)
      _ ->
        changeset
    end
  end

  def get_message_body(model) do
    if model.body_encrypted do
      {:ok, body} = ExCrypto.decrypt(@keyphrase, model.iv, model.body_encrypted)
      body
    else
      nil
    end
  end
end
