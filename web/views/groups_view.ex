defmodule Thegm.GroupsView do
  use Thegm.Web, :view

  def render("memberof.json", %{group: group, user: user}) do
    included = Enum.map(group.group_members, &user_hydration/1)
    data = member_json(group, user)
    %{
      data: data,
      included: included
    }
  end

  def render("adminof.json", %{group: group, user: user}) do
    included = Enum.map(group.group_members, &user_hydration/1)
    data = member_json(group, user)
    %{
      data: data,
      included: included
    }
  end

  def render("notmember.json", %{group: group, user: user}) do
    data = non_member_json(group, user)
    %{data: data}
  end

  def render("search.json", %{groups: groups, meta: meta, user: user}) do
    data = Enum.map(groups, fn g -> search_json(g, user) end)

    %{meta: search_meta(meta), data: data}
  end

  def member_json(group, user) do
    status = group_member_status(group, user)

    %{
      type: "groups",
      id: group.id,
      attributes: %{
        name: group.name,
        description: group.description,
        address: group.address,
        geo: Thegm.GeoView.geo(group.geom),
        games: group.games,
        members: length(group.group_members),
        slug: group.slug,
        member_status: status
      },
      relationships: %{
        group_members: Thegm.GroupMembersView.groups_users(group.group_members)
      }
    }
  end

  def non_member_json(group, user) do
    status = group_member_status(group, user)

    %{
      type: "groups",
      id: group.id,
      attributes: %{
        name: group.name,
        description: group.description,
        games: group.games,
        members: length(group.group_members),
        slug: group.slug,
        member_status: status
      }
    }
  end

  def search_json(group, user) do
    status = group_member_status(group, user)

     %{
      type: "groups",
      id: group.id,
      attributes: %{
        name: group.name,
        description: group.description,
        games: group.games,
        members: length(group.group_members),
        slug: group.slug,
        distance: group.distance,
        member_status: status
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

  def users_groupmembers_groups(group) do
    %{
      name: group.name,
      description: group.description,
      games: group.games,
      slug: group.slug
    }
  end

  def search_meta(meta) do
    %{total: meta.total, count: meta.count, limit: meta.limit, offset: meta.offset}
  end

  def relationship_data(groupmember) do
    %{
      id: groupmember.groups_id,
      type: "groups"
    }
  end

  def group_member_status(group, user) do
    case get_member(group.group_members, user.id) do
      nil ->
        case group.join_requests do
          # user has not previously requested to join the group
          [] ->
            false
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

  def get_member([head | tail], user_id) do
    cond do
      head.users_id == user_id ->
        head
      true ->
        get_member(tail, user_id)
    end
  end
end
