defmodule Thegm.ThreadsView do
  use Thegm.Web, :view

  def render("show.json", %{thread: thread}) do
    cond do
      thread.deleted == true ->
        %{
          data: show(thread)
        }
      true ->
        %{
          data: show(thread),
          included: [user_hydration(thread.users)]
        }
    end
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
      attributes: Thegm.UsersView.users_public(user)
    }
  end

  def relationship_data(thread) do
    %{
      id: thread.id,
      type: "threads"
    }
  end

  def just_thread(thread) do
    cond do
      thread.deleted == true ->
        %{
          type: "threads",
          id: thread.id,
          attributes: %{
            title: "[deleted]",
            body: "[deleted]",
            deleted: thread.deleted,
            pinned: thread.pinned,
            inserted_at: thread.inserted_at,
            updated_at: thread.updated_at
          }
        }
      true ->
        %{
          type: "threads",
          id: thread.id,
          attributes: %{
            title: thread.title,
            body: thread.body,
            deleted: thread.deleted,
            pinned: thread.pinned,
            inserted_at: thread.inserted_at,
            updated_at: thread.updated_at
          }
        }
    end
  end

  def show(thread) do
    cond do
      thread.deleted == true ->
        %{
          type: "threads",
          id: thread.id,
          attributes: %{
            title: "[deleted]",
            body: "[deleted by " <> thread.threads_deleted.deleter_role <> "]",
            comments: length(thread.thread_comments),
            pinned: thread.pinned,
            deleted: thread.deleted,
            inserted_at: thread.inserted_at,
            updated_at: thread.updated_at
          }
        }
      true ->
        %{
          type: "threads",
          id: thread.id,
          attributes: %{
            title: thread.title,
            body: thread.body,
            comments: length(thread.thread_comments),
            pinned: thread.pinned,
            deleted: thread.deleted,
            inserted_at: thread.inserted_at,
            updated_at: thread.updated_at
          },
          relationships: %{
            users: Thegm.UsersView.relationship_data(thread.users)
          },
        }
    end
  end

  def included_users([], included) do
    included
  end

  def included_users([head | tail], included) do
    included = cond do
      head.deleted ->
        included
      !Enum.member?(included, head.users) ->
        included ++ [head.users]
      true ->
        included
    end
    included_users(tail, included)
  end
end
