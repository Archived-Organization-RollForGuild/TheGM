defmodule Thegm.Presence do
    @moduledoc "Module configuring the connection to our presence server"
    use Phoenix.Presence, otp_app: :thegm,
                          pubsub_server: Thegm.PubSub
  end
