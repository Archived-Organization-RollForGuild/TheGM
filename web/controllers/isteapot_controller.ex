defmodule Thegm.IsTeapotController do
  use Thegm.Web, :controller

  def index(conn, _) do
    conn |> put_status(:im_a_teapot) |> render(Thegm.DataMessagesView, "message.json", %{message: "I'm a little teapot\nShort and stout\nHere is my handle\nHere is my spout\n\nWhen I get all steamed up\nHear me shout\n\"Tip me over\nand pour me out!\""})
  end
end
