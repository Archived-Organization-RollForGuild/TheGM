defmodule Thegm.MetaView do
  use Thegm.Web, :view

  def meta(meta) do
    %{total: meta.total, count: meta.count, limit: meta.limit, offset: meta.offset}
  end
end
# credo:disable-for-this-file
