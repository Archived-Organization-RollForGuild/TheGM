defmodule Thegm.BetasubController do
  use Thegm.Web, :controller

  alias Thegm.Betasub

  def create(conn, %{"email" => email}) do
    # email
    {:ok, final} = Enum.fetch(Enum.filter(Mailchimp.Account.get! |> Mailchimp.Account.lists!, fn(x) -> Map.get(x, :name) == "Roll For Guild" end), 0)
    case Mailchimp.List.create_member(final, email, :subscribed, %{}, %{}) do
      {:ok, _resp} ->
        send_resp(conn, :created, "")
      {:error, resp} ->
        conn
        |> put_status(:bad_request)
        |> render("") #TODO
    end
  end
end
