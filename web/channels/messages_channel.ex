defmodule Thegm.MessagesChannel do
  @moduledoc "Module for handling websocket direct messages"

  use Phoenix.Channel
  import Ecto.Query
  alias Thegm.{
    Repo,
    Presence,
    MessageThreads,
    ErrorView,
    MessageParticipants,
    Messages,
    MessageThreadsView,
    MessagesView
  }

  def join("message_threads:index", _, socket) do
    message_threads_query = from mt in MessageThreads,
      left_join: mp in assoc(mt, :message_participants),
      left_join: u in assoc(mp, :users),
      where: mp.users_id == ^socket.assigns.users_id,
      preload: [{:message_participants, :users}]

    case Repo.all(message_threads_query) do
      nil ->
        {:ok, socket}

      message_threads ->
        response = MessageThreadsView.render("index.json", %{threads: message_threads, meta: %{
          limit: 0,
          offset: 0,
          count: length(message_threads),
          total: length(message_threads)
        }})
        {:ok, response, socket}
    end
  end

  def join("messages:index", _, socket) do
    message_threads_query = from mt in MessageThreads,
      left_join: mp in assoc(mt, :message_participants),
      left_join: u in assoc(mp, :users),
      where: mp.users_id == ^socket.assigns.users_id,
      preload: [{:message_participants, :users}]

    case Repo.all(message_threads_query) do
      nil ->
        {:ok, socket}

      message_threads ->
        response = MessageThreadsView.render("index.json", %{threads: message_threads, meta: %{
          limit: 0,
          offset: 0,
          count: length(message_threads),
          total: length(message_threads)
        }})
        {:ok, response, socket}
    end
  end

  def join("message_threads:" <> message_threads_id, _, socket) do
    users_id = socket.assigns.users_id

    message_thread = Repo.one(
      from mt in MessageThreads,
      left_join: mp in assoc(mt, :message_participants),
      left_join: u in assoc(mp, :users),
      where: mt.id == ^message_threads_id and (mp.users_id == ^users_id and mp.status == "member"),
      preload: [{:message_participants, :users}]
    )

    case message_thread do
      nil ->
        {:error, ErrorView.render("error.json", errors: ["Message thread not found"])}

      _ ->
        send(self(), :after_join)
        response = MessageThreadsView.render("show.json", %{thread: message_thread})
        {:ok, response, assign(socket, :message_threads_id, message_threads_id)}
    end
  end

  def handle_info(:after_join, socket) do
    push socket, "presence_state", Presence.list(socket)
    {:ok, _} = Presence.track(socket, socket.assigns.users_id, %{
      online_at: inspect(System.system_time(:seconds)),
      typing: false
    })
    {:noreply, socket}
  end

  def handle_in("messages:typing", %{"data" => %{"attributes" => params}}, socket) do
    Presence.update(socket, socket.assigns.users_id, fn
      meta -> Map.put(meta, :typing, params["value"])
    end)
    {:noreply, socket}
  end

  def handle_in("message_threads:create", %{"data" => %{"attributes" => params}}, socket) do
    changeset = MessageThreads.create_changeset(%MessageThreads{}, params)

    cond do
      changeset.valid? == false ->
        response = ErrorView.render("errors.json", "A message thread needs message participants")
        {:reply, {:error, response}, socket}

      [params["message_participants"]] ->
        thread = Repo.insert!(changeset)
        invalid_items = Enum.reject(params["message_participants"], fn x -> x["type"] == "message-participants" end)

        unless length(invalid_items) > 0 do
          {:reply, add_message_participants(params, socket.assigns.users_id, thread.id), socket}

        end
      true ->
        response = ErrorView.render("errors.json", %{changeset: changeset})
        {:reply, {:error, response}, socket}
    end
  end

  def handle_in("messages:create", %{"data" => %{"attributes" => params}}, socket) do
    users_id = socket.assigns.users_id
    message_threads_id = socket.assigns.message_threads_id

    message_thread = Repo.one(
      from mt in MessageThreads,
      left_join: mp in assoc(mt, :message_participants),
      left_join: u in assoc(mp, :users),
      where: mt.id == ^message_threads_id and (mp.users_id == ^users_id and mp.status == "member"),
      preload: [{:message_participants, :users}]
    )

    case message_thread do
      nil ->
        {:error, ErrorView.render("error.json", errors: ["Message thread not found"])}

      _ ->
        changeset = Messages.new_message(
          %Messages{},
          params,
          users_id,
          message_threads_id
        )

        if changeset.valid? do
          {:reply, send_message(changeset, socket), socket}
        else
          response = ErrorView.render("errors.json", %{changeset: changeset})
          {:reply, {:error, response}, socket}
        end
    end
  end

  def add_message_participants(params, users_id, threads_id) do
    participants = Enum.map(params["message_participants"], fn (msg_par) ->
      %{
        id: UUID.uuid4,
        users_id: msg_par["id"],
        message_threads_id: threads_id,
        status: "member",
        silenced: false,
        inserted_at: NaiveDateTime.utc_now(),
        updated_at: NaiveDateTime.utc_now()
      }
    end)

    participants = participants ++ [%{
      id: UUID.uuid4,
      users_id: users_id,
      message_threads_id: threads_id,
      status: "member",
      silenced: false,
      inserted_at: NaiveDateTime.utc_now(),
      updated_at: NaiveDateTime.utc_now()
    }]

    case Repo.insert_all(MessageParticipants, participants, [on_conflict: :raise]) do
      {_, nil} ->
        thread = Repo.get(MessageThreads, threads_id)
        |> Repo.preload([{:message_participants, :users}])

        response = MessageThreadsView.render("show.json", %{thread: thread})
        {:ok, response}
      {:error, changeset} ->
        response = ErrorView.render("errors.json", %{changeset: changeset})
        {:error, response}
    end
  end

  def send_message(message, socket) do
    case Repo.insert(message) do
      {:ok, resp} ->
        created_message = Repo.one(
          from m in Messages,
          left_join: u in assoc(m, :users),
          left_join: mt in assoc(m, :message_threads),
          where: m.id == ^resp.id,
          preload: [:users, :message_threads]
        )

        response = MessagesView.render("show.json", %{message: created_message})
        broadcast! socket, "messages:new", response
        {:ok, response}
      {:error, resp} ->
        error_list = Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end)
        response = ErrorView.render("errors.json", errors: error_list)
        {:error, response}
    end
  end
end
