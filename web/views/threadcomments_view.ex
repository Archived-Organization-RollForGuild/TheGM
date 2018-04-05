defmodule Thegm.ThreadCommentsView do
  use Thegm.Web, :view

  def render("create.json", %{comment: comment}) do
    %{
      data: show(comment),
      included: [user_hydration(comment.users), thread_hydration(comment.threads)]
    }
  end

  def render("index.json", %{comments: comments, meta: meta}) do
    distinct_users = Thegm.ThreadsView.included_users(comments, [])

    # Hydrate only if there are things to hydrate
    hydrated_thread = case comments do
      [] ->
        []
      [head | _] ->
        [thread_hydration(head.threads)]
    end
    %{
      meta: meta,
      data: Enum.map(comments, &show/1),
      included: Enum.map(distinct_users, &user_hydration/1) ++ hydrated_thread
    }
  end

  def render("show.json", %{comment: comment}) do
    cond do
      comment.deleted == true ->
        %{
          data: show(comment),
          included: [thread_hydration(comment.threads)]
        }
      true ->
        %{
          data: show(comment),
          included: [user_hydration(comment.users), thread_hydration(comment.threads)]
        }
    end
  end

  def show(comment) do
    cond do
      comment.deleted == true ->
        %{
          type: "thread-comments",
          id: comment.id,
          attributes: %{
            comment: "[deleted by " <> comment.thread_comments_deleted.deleter_role <> "]",
            inserted_at: comment.inserted_at,
            updated_at: comment.updated_at,
            deleted: comment.deleted
          },
          relationships: %{
            threads: Thegm.ThreadsView.relationship_data(comment.threads)
          }
        }
      true ->
        %{
          type: "thread-comments",
          id: comment.id,
          attributes: %{
            comment: comment.comment,
            inserted_at: comment.inserted_at,
            updated_at: comment.updated_at,
            deleted: comment.deleted
          },
          relationships: %{
            users: Thegm.UsersView.relationship_data(comment.users),
            threads: Thegm.ThreadsView.relationship_data(comment.threads)
          }
        }
    end
  end

  def user_hydration(user) do
    %{
      type: "users",
      id: user.id,
      attributes: Thegm.UsersView.users_public(user)
    }
  end

  def thread_hydration(thread) do
    Thegm.ThreadsView.just_thread(thread)
  end
end
