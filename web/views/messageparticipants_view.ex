defmodule Thegm.MessageParticipantsView do
  use Thegm.Web, :view
  alias Thegm.{MetaView, UsersView}

  def render("index.json", %{message_participants: message_participants, meta: meta}) do
    %{
      meta: MetaView.meta(meta),
      data: Enum.map(message_participants, &hydrate_message_participant/1)
    }
  end

  def hydrate_message_participant(message_participant) do
    %{
      type: "message-participants",
      id: message_participant.users_id,
      attributes: Map.merge(UsersView.users_public(message_participant.users), %{
        status: message_participant.status,
        silenced: message_participant.silenced,
        inserted_at: message_participant.inserted_at
      })
    }
  end

  def threads_users(message_participants) do
    %{
      data: Enum.map(message_participants, fn(x) -> UsersView.relationship_data(x.users) end)
    }
  end
end

