defmodule Thegm.ThreadsView do
  use Thegm.Web, :view

  def render("show.json", %{thread: thread}) do
    %{
      data: %{
        type: "threads",
        id: thread.id,
        attributes: %{
          title: thread.title,
          body: thread.body,
          pinned: thread.pinned,
          inserted_at: thread.inserted_at
        },
        relationships: %{
          users: Thegm.UsersView.relationship_data(thread.users)
        },
        included: []
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
end
