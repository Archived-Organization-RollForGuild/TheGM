defmodule Thegm.GroupsView do
  use Thegm.Web, :view


  def render("show.json", %{group: group, users_id: users_id}) do
    data = show_json(group, users_id)
    status = data[:attributes][:member_status]
    cond do
       status == "member" or status == "admin" ->
        included = Enum.map(group.group_members, &user_hydration/1) ++ Enum.map(group.group_games, &game_hydration/1)
        %{
          data: data,
          included: included
        }
      true ->
        %{
          data: data
        }
    end
  end

  def render("index.json", %{groups: groups, meta: meta, users_id: users_id}) do
    data = Enum.map(groups, fn g -> show_json(g, users_id) end)
    %{meta: search_meta(meta), data: data}
  end

  def show_json(group, user) do
    status = group_member_status(group, user)
    cond do
      status == "member" or status == "admin" ->
       member_json(group, status)
      true ->
        non_member_json(group, status)
    end
  end

  def member_json(group, status) do
    %{
      type: "groups",
      id: group.id,
      attributes: %{
        name: group.name,
        description: group.description,
        address: group.address,
        geo: Thegm.GeoView.geo(group.geom),
        members: length(group.group_members),
        slug: group.slug,
        member_status: status,
        discoverable: group.discoverable
      },
      relationships: %{
        group_members: Thegm.GroupMembersView.groups_users(group.group_members),
        group_games: Thegm.GroupGamesView.groups_games(group.group_games),
        group_events: Thegm.GroupEventsView.relationship_link(group)
      }
    }
  end

  def non_member_json(group, status) do
    %{
      type: "groups",
      id: group.id,
      attributes: %{
        name: group.name,
        description: group.description,
        members: length(group.group_members),
        slug: group.slug,
        member_status: status,
        discoverable: group.discoverable
      },
      relationships: %{
        group_games: Thegm.GroupGamesView.groups_games(group.group_games),
        group_events: Thegm.GroupEventsView.relationship_link(group)
      }
    }
  end

  def base_json(group) do
    %{
      type: "groups",
      id: group.id,
      attributes: %{
        name: group.name,
        description: group.description,
        slug: group.slug,
        discoverable: group.discoverable
      }
    }
  end


  def user_hydration(member) do
    group_member = %{
      type: "users",
      id: member.users_id,
      attributes: Thegm.UsersView.users_private(member.users)
    }
    Map.put(group_member.attributes, :role, member.role)
    group_member
  end

  def game_hydration(user_game) do
    %{
      type: "games",
      id: user_game.games_id,
      attributes: Thegm.GamesView.users_usergames_games(user_game.games)
    }
  end

  def users_groupmembers_groups(group) do
    %{
      name: group.name,
      description: group.description,
      slug: group.slug
    }
  end

  def search_meta(meta) do
    %{total: meta.total, count: meta.count, limit: meta.limit, offset: meta.offset}
  end

  def relationship_data(group) do
    %{
      id: group.id,
      type: "groups"
    }
  end

  def group_member_status(group, users_id) do
    case get_member(group.group_members, users_id) do
      nil ->
        case group.join_requests do
          # user has not previously requested to join the group
          [] ->
            nil
          # user has previously requested to join the group
          join_requests ->
            # Because we ordered by updated descending, get the most recent request
            last = hd(join_requests)
            cond do
              # Last request is still open, error
              last.status == nil ->
                "pending"
              # Last request was ignored, check how old it is
              last.status == "ignored" ->
                # Calculated how long it has been since they last requested
                inserted_at = last.inserted_at |> DateTime.from_naive!("Etc/UTC")
                diff = DateTime.diff(DateTime.utc_now, inserted_at, :second)
                # if it has been less than 60 days since they last requested
                if (diff / 60 / 60 / 24) < 60  do
                  "pending"
                else
                  nil
                end
              true ->
                nil
            end
        end
      member ->
        member.role
    end
  end

  def get_member([], _) do
    nil
  end

  def get_member([head | tail], users_id) do
    cond do
      head.users_id == users_id ->
        head
      true ->
        get_member(tail, users_id)
    end
  end
end
