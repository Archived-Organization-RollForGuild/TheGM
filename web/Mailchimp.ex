defmodule Thegm.Mailchimp do
  @moduledoc "Module for handling mailchimp operations"

  def subscribe_new_user(email) do
    # email
    {:ok, final} = Enum.fetch(Enum.filter(Mailchimp.Account.get! |> Mailchimp.Account.lists!, fn(x) -> Map.get(x, :name) == "Roll For Guild" end), 0)
    Mailchimp.List.create_member(final, email, :subscribed, %{}, %{})
  end
end
