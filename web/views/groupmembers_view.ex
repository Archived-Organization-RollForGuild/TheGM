defmodule Thegm.GroupMembersView do
  use Thegm.Web, :view

  def render("members.json", %{members: members}) do
    %{data: Enum.map(members, &member/1)}
  end

  def member(member) do
    base = Application.get_env(:thegm, :api_url)
    %{
      type: "members",
      id: member.id,
      attributes: %{
        user_id: member.users_id,
        group_id: member.groups_id,
        role: member.role
      },
      relationships: %{
        group: %{
          links: %{
            self: base <> "/groups/" <> member.groups_id
          }
        },
        user: %{
          links: %{
            self: base <> "/users/" <> member.users_id
          }
        }
      }
    }
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
