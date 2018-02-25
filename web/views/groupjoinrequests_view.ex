defmodule Thegm.GroupJoinRequestsView do
  @moduledoc "View for requests to join a group"

  use Thegm.Web, :view

  def render("show.json", %{requests: requests, meta: meta}) do
    %{
      meta: Thegm.MetaView.meta(meta),
      data: Enum.map(requests, &hydrate_user/1)
    }
  end

  def hydrate_user(request) do
    %{}
  end


end
