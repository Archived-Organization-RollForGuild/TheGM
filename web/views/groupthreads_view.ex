defmodule Thegm.GroupThreadsView do
  use Thegm.Web, :view

  def render("show.json", %{thread: thread}) do
    cond do
      thread.deleted == true ->
        %{
          data: show(thread),
          included: [group_hydration(thread.groups)]
        }
      true ->
        %{
          data: show(thread),
          included: [user_hydration(thread.users), group_hydration(thread.groups)]
        }
    end
  end

  def render("index.json", %{threads: threads, meta: meta}) do
    distinct_users = Thegm.ThreadsView.included_users(threads, [])
    # Hydrate only if there are things to hydrate
    hydrated_group = case threads do
      [] ->
        []
      [head | _] ->
        [group_hydration(head.groups)]
    end
    %{
      meta: meta,
      data: Enum.map(threads, &show/1),
      included: Enum.map(distinct_users, &user_hydration/1) ++ hydrated_group
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

  def group_hydration(group) do
    Thegm.GroupsView.base_json(group)
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
    cond do
      thread.deleted == true ->
        %{
          type: "threads",
          id: thread.id,
          attributes: %{
            title: "[deleted]",
            body: "[deleted by " <> thread.group_threads_deleted.deleter_role <> "]",
            comments: length(thread.group_thread_comments),
            pinned: thread.pinned,
            inserted_at: thread.inserted_at
          },
          relationships: %{
            groups: Thegm.GroupsView.relationship_data(thread.groups)
          },
        }
      true ->
        %{
          type: "threads",
          id: thread.id,
          attributes: %{
            title: thread.title,
            body: thread.body,
            comments: length(thread.group_thread_comments),
            pinned: thread.pinned,
            inserted_at: thread.inserted_at
          },
          relationships: %{
            users: Thegm.UsersView.relationship_data(thread.users),
            groups: Thegm.GroupsView.relationship_data(thread.groups)
          },
        }
    end
  end
end
