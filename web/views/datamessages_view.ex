defmodule Thegm.DataMessagesView do
  @moduledoc "View for data messages"

  use Thegm.Web, :view

  def render("message.json", param) do
    %{
        data: %{type: "message", message: param.message}
    }
  end
end
