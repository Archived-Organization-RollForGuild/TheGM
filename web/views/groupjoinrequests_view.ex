defmodule Thegm.GroupJoinRequestsView do
  use Thegm.Web, :view

  def render("show.json", %{requests: requests, meta: meta}) do
    %{
      meta: Thegm.MetaView.meta(meta),
      data: Enum.map(requests, &hydrate_pending_user/1)
    }
  end

  def hydrate_pending_user(request) do
    join_request = %{
      type: "join-requests",
      id: request.users_id,
      attributes: Thegm.UsersView.users_public(request.users)
    }
    join_request = put_in(join_request, [:attributes, :status], "pending")
    put_in(join_request, [:attributes, :requested_at], request.inserted_at)
  end
end
