defmodule Thegm.UsersView do
  use Thegm.Web, :view

  def render("public.json", %{user: user}) do
    included = Enum.map(user.group_members, &group_hydration/1) ++ Enum.map(user.user_games, &game_hydration/1)

    %{
      data: %{
        type: "users",
        id: user.id,
        attributes: users_public(user),
        relationships: %{
          groups: Thegm.GroupMembersView.users_groups(user.group_members),
          games: Thegm.UserGamesView.users_games(user.user_games)
        }
      },
      included: included
    }
  end

  def render("private.json", %{user: user}) do
    included = Enum.map(user.group_members, &group_hydration/1) ++
               Enum.map(user.user_games, &game_hydration/1) ++
               [preferences_hydration(user.preferences)]

    %{
      data: %{
        type: "users",
        id: user.id,
        attributes: users_private(user),
        relationships: %{
          groups: Thegm.GroupMembersView.users_groups(user.group_members),
          games: Thegm.UserGamesView.users_games(user.user_games),
          preferences: Thegm.PreferencesView.relationship_data(user.preferences)
        }
      },
      included: included
    }
  end

  #show multiple users
  def render("index.json", %{users: users}) do
    %{
      users: Enum.map(users, &users_public/1)
    }
  end

  def group_hydration(membership) do
    %{
      type: "groups",
      id: membership.groups_id,
      attributes: Thegm.GroupsView.users_groupmembers_groups(membership.groups)
    }
  end

  def game_hydration(user_game) do
    %{
      type: "games",
      id: user_game.games_id,
      attributes: Thegm.GamesView.users_usergames_games(user_game.games)
    }
  end

  def preferences_hydration(preferences) do
    %{
      type: "preferences",
      id: preferences.id,
      attributes: Thegm.PreferencesView.users_preferences(preferences)
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
# credo:disable-for-this-file
