defmodule Thegm.UsersView do
  use Thegm.Web, :view

  #show multiple users
  def render("index.json", %{users: users}) do
    %{
      users: Enum.map(users, &users_public/1)
    }
  end

  def users_public(user) do
    %{
      username: user.username
    }
  end

  def users_private(user) do
    %{
      username: user.username,
      email: user.email
    }
  end

  def relationship_data(user) do
    %{
      id: user.id,
      type: "users"
    }
  end
end
