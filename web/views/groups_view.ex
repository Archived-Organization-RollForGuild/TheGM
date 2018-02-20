defmodule Thegm.GroupsView do
  use Thegm.Web, :view

  def render("memberof.json", %{group: group}) do
    included = Enum.map(group.group_members, &user_hydration/1)
    data = member_json(group, "member")
    %{
      data: data,
      included: included
    }
  end

  def render("adminof.json", %{group: group}) do
    included = Enum.map(group.group_members, &user_hydration/1)
    data = member_json(group, "admin")
    %{
      data: data,
      included: included
    }
  end

  def render("notmember.json", %{group: group}) do
    data = non_member_json(group, nil)
    %{data: data}
  end

  def render("pendingmember.json", %{group: group}) do
    data = non_member_json(group, "pending")
    %{data: data}
  end

  def render("search.json", %{groups: groups, meta: meta}) do
    %{meta: search_meta(meta), data: Enum.map(groups, &search_json/1)}
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

  def non_member_json(group, status) do
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

  def search_json(group) do
     %{
      type: "groups",
      id: group.id,
      attributes: %{
        name: group.name,
        description: group.description,
        games: group.games,
        members: length(group.group_members),
        slug: group.slug,
        distance: group.distance
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
end
