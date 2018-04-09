defmodule Thegm.DataMessagesView do
  use Thegm.Web, :view

  def render("message.json", param) do
    %{
        data: %{type: "message", message: param.message}
    }
  end
end
# credo:disable-for-this-file
