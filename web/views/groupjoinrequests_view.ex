defmodule Thegm.GroupJoinRequestsView do
  use Thegm.Web, :view

  def render("show.json", %{requests: requests, meta: meta}) do
    %{
      meta: Thegm.MetaView.meta(meta),
      data: Enum.map(requests, &hydrate_user/1)
    }
  end

  def hydrate_user(request) do
    IO.inspect request
    %{}
  end


end
