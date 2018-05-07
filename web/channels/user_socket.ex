defmodule Thegm.UserSocket do
  use Phoenix.Socket
  alias Thegm.{Repo, Sessions, ErrorView}
  import Ecto.Query

  ## Channels
  channel "message_threads:*", Thegm.MessagesChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"userToken" => token}, socket) do
    case find_session_by_token(token) do
      :error ->
        unauthenticated_error = ErrorView.render(
          "error.json",
          errors: ["Unauthorized request, please login"]
        )

        {:error, unauthenticated_error}

      {:ok, session} ->
        {:ok, assign(socket, :users_id, session.users_id)}
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Thegm.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(socket), do: "users_socket:#{socket.assigns.users_id}"

  def find_session_by_token(token) do
    case Repo.one(from s in Sessions, where: s.token == ^token) do
      nil -> :error
      session -> {:ok, session}
    end
  end
end
