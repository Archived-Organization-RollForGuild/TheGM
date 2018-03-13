defmodule Thegm.ThreadsView do
  use Thegm.Web, :view

  def render("show.json", %{thread: thread}) do
    %{
      data: show(thread),
      included: [user_hydration(thread.users)]
    }
  end

  def render("index.json", %{threads: threads, meta: meta}) do
    distinct_users = included_users(threads, [])

    %{
      meta: meta,
      data: Enum.map(threads, &show/1),
      included: Enum.map(distinct_users, &user_hydration/1)
    }
  end

  def user_hydration(user) do
    %{
      type: "users",
      id: user.id,
      attributes: Thegm.UsersView.users_private(user)
    }
  end

  def relationship_data(thread) do
    %{
      id: thread.id,
      type: "threads"
    }
  end

  def just_thread(thread) do
    %{
      type: "threads",
      id: thread.id,
      attributes: %{
        title: thread.title,
        body: thread.body,
        pinned: thread.pinned,
        inserted_at: thread.inserted_at
      }
    }
  end

  def show(thread) do
    %{
      type: "threads",
      id: thread.id,
      attributes: %{
        title: thread.title,
        body: thread.body,
        comments: length(thread.thread_comments),
        pinned: thread.pinned,
        inserted_at: thread.inserted_at
      },
      relationships: %{
        users: Thegm.UsersView.relationship_data(thread.users)
      },
    }
  end

  def included_users([], included) do
    included
  end

  def included_users([head | tail], included) do
    included = cond do
      length(included) == 0 ->
        included ++ [head.users]
      Enum.member?(included, head.users) ->
        included ++ [head.users]
    end
  end
end
