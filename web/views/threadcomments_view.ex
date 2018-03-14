defmodule Thegm.ThreadCommentsView do
  use Thegm.Web, :view

  def render("create.json", %{comment: comment}) do
    %{
      data: show(comment),
      included: [user_hydration(comment.users), thread_hydration(comment.threads)]
    }
  end

  def render("index.json", %{comments: comments, meta: meta}) do
    distinct_users = included_users(comments, [])
    [head | _] = comments
    %{
      meta: meta,
      data: Enum.map(comments, &show/1),
      included: Enum.map(distinct_users, &user_hydration/1) ++ [thread_hydration(head.threads)]
    }
  end

  def show(comment) do
    %{
      type: "thread-comments",
      id: comment.id,
      attributes: %{
        comment: comment.comment,
        inserted_at: comment.inserted_at
      },
      relationships: %{
        users: Thegm.UsersView.relationship_data(comment.users),
        threads: Thegm.ThreadsView.relationship_data(comment.threads)
      }
    }
  end

  def user_hydration(user) do
    %{
      type: "users",
      id: user.id,
      attributes: Thegm.UsersView.users_private(user)
    }
  end

  def thread_hydration(thread) do
    Thegm.ThreadsView.just_thread(thread)
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
