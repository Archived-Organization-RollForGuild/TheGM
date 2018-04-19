defmodule Thegm.MessagesView do
  use Thegm.Web, :view
  alias Thegm.{
    Messages,
    UsersView,
    MessageThreadsView
  }

  def render("show.json", %{message: message}) do
    %{
      data: message_show(message)
    }
  end

  def render("index.json", %{messages: messages, meta: meta}) do
    data = Enum.map(messages, &message_show/1)

    %{meta: search_meta(meta), data: data}
  end

  def message_show(message) do
    body = Messages.get_message_body(message)

    %{
      type: "messages",
      id: message.id,
      attributes: %{
        body: body,
        inserted_at: message.inserted_at,
        updated_at: message.updated_at
      },
      relationships: %{
        users: UsersView.relationship_data(message.users),
        message_threads: MessageThreadsView.relationship_data(message.message_threads)
      }
    }
  end

  def relationship_data(message) do
    %{
      id: message.id,
      type: "messages"
    }
  end

  def search_meta(meta) do
    %{total: meta.total, count: meta.count, limit: meta.limit, offset: meta.offset}
  end
end
