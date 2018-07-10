defmodule Thegm.NotificationStatsView do
  use Thegm.Web, :view

  def render("show.json", %{new: new}) do
    %{
      data: %{
        type: "notification-stats",
        attributes: %{
          new: new
        }
      }
    }
  end
end
