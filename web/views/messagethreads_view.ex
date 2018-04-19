defmodule Thegm.MessageThreadsView do
  use Thegm.Web, :view
  alias Thegm.{MessageThreads, MessageParticipantsView}

  def render("show.json", %{thread: thread}) do
    included = Enum.map(thread.message_participants,
      &MessageParticipantsView.hydrate_message_participant/1)
    %{
      data: thread_show(thread),
      included: included
    }
  end

  def render("index.json", %{threads: threads, meta: meta}) do
    data = Enum.map(threads, &thread_show/1)

    %{meta: search_meta(meta), data: data}
  end

  def thread_show(thread) do
    title = MessageThreads.get_thread_title(thread)

    %{
      type: "message_threads",
      id: thread.id,
      attributes: %{
        title: title,
        inserted_at: thread.inserted_at,
        updated_at: thread.updated_at
      },
      relationships: %{
        message_participants: MessageParticipantsView.threads_users(thread.message_participants)
      }
    }
  end

  def relationship_data(thread) do
    %{
      id: thread.id,
      type: "message_threads"
    }
  end

  def search_meta(meta) do
    %{total: meta.total, count: meta.count, limit: meta.limit, offset: meta.offset}
  end

  def included_threads([], included) do
    included
  end


  # Expects the list of models to each have a preloaded game
  def included_threads([head | tail], included) do
    included = if Enum.member?(included, head.message_threads) do
      included
    else
      included ++ [head.message_threads]
    end
    included_threads(tail, included)
  end
end
