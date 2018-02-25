defmodule Thegm.MetaView do
  @moduledoc "View for meta information"

  use Thegm.Web, :view

  def meta(meta) do
    %{total: meta.total, count: meta.count, limit: meta.limit, offset: meta.offset}
  end
end
