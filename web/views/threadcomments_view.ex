defmodule Thegm.ThreadCommentsView do
  use Thegm.Web, :view

  def render("create.json", %{comment: comment}) do
    comment_with_thread_relation(comment)
  end

  def comment_with_thread_relation(comment) do
    %{
      data: %{
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
      },
      included: [user_hydration(comment.users), thread_hydration(comment.threads)]
    }
  end

  def comment_without_thread_relation(comment) do
    %{
      data: %{
        type: "thread-comments",
        id: comment.id,
        attributes: %{
          comment: comment.comment,
          inserted_at: comment.inserted_at
        },
        relationships: %{
          users: Thegm.UsersView.relationship_data(comment.users)
        }
      },
      included: [user_hydration(comment.users)]
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
end
