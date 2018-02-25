defmodule Thegm.UsersView do
  @moduledoc "View for users"

  use Thegm.Web, :view

  def render("public.json", %{user: user}) do
    included = Enum.map(user.group_members, &group_hydration/1)

    %{
      data: %{
        type: "users",
        id: user.id,
        attributes: users_public(user),
        relationships: %{
          groups: Thegm.GroupMembersView.users_groups(user.group_members)
        }
      },
      included: included
    }
  end

  def render("private.json", %{user: user}) do
    included = Enum.map(user.group_members, &group_hydration/1)

    %{
      data: %{
        type: "users",
        id: user.id,
        attributes: users_private(user),
        relationships: %{
          groups: Thegm.GroupMembersView.users_groups(user.group_members)
        }
      },
      included: included
    }
  end


  def group_hydration(membership) do
    group_membership = %{
      type: "groups",
      id: membership.groups_id,
      attributes: Thegm.GroupsView.users_groupmembers_groups(membership.groups)
    }
  end

  #show multiple users
  def render("index.json", %{users: users}) do
    %{
      users: Enum.map(users, &users_public/1)
    }
  end

  def users_public(user) do
    %{
      username: user.username,
      bio: user.bio,
      avatar: user.avatar
    }
  end

  def users_private(user) do
    %{
      username: user.username,
      email: user.email,
      bio: user.bio,
      avatar: user.avatar
    }
  end

  def relationship_data(user) do
    %{
      id: user.id,
      type: "users"
    }
  end
end
