defmodule Thegm.GroupMembersView do
  use Thegm.Web, :view

  def render("index.json", %{members: members, meta: meta}) do
    %{
      meta: Thegm.MetaView.meta(meta),
      data: Enum.map(members, &hydrate_group_member/1)
    }
  end

  def hydrate_group_member(member) do
    groupmember_hydration = %{
      type: "group-members",
      id: member.users_id,
      attributes: Thegm.UsersView.users_public(member.users)
    }
    groupmember_hydration = put_in(groupmember_hydration, [:attributes, :role], member.role)
    put_in(groupmember_hydration, [:attributes, :inserted_at], member.inserted_at)
  end


  def groups_users(members) do
    %{
      data: Enum.map(members, fn(x) -> Thegm.UsersView.relationship_data(x.users) end)
    }
  end

  def users_groups(members) do
    %{
      data: Enum.map(members, fn(x) -> Thegm.GroupsView.relationship_data(x.groups) end)
    }
  end
end
