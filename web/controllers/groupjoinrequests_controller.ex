defmodule Thegm.GroupJoinRequestsController do
  use Thegm.Web, :controller

  alias Thegm.GroupJoinRequests

  # TODO: This should probably be refactored (ASAP) and being should "blocked" stored somewhere else - Quigley
  # NOTE: This is baaaad spaghetti code - Quigley
  def create(conn, %{"group_id" => group_id}) do
    user_id = conn.assigns[:current_user].id
    #
    case Repo.all(from m in Thegm.GroupMembers, where: m.groups_id == ^group_id and m.users_id == ^user_id) do
      # confirmed user is not already part of group
      nil ->
        join_changeset = GroupJoinRequests.create_changeset(%GroupJoinRequests{}, %{group_id: group_id, user_id: user_id})
        case Repo.all(from gj in GroupJoinRequests, where: gj.groups_id == ^group_id and gj.users_id == ^user_id, order_by: [desc: gj.updated_at]) do
          # user has not previously requested to join the group, commit request
          nil ->
            case Repo.insert(join_changeset) do
              {:ok, _} ->
                send_resp(conn, :created, "")
              {:error, resp} ->
                error_list = Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end)
                conn
                |> put_status(:bad_request)
                |> render(Thegm.ErrorView, "error.json", errors: error_list)
            end
          # user has previously requested to join the group
          resp ->
            # Because we ordered by updated descending, get the most recent request
            last = hd(resp)
            cond do
              # Last request is still open, error
              last.status == nil ->
                conn
                |> put_status(:conflict)
                |> render(Thegm.ErrorView, "error.json", errors: ["A request to join this group already exists"])
              # Last request was ignored, check how old it is
              last.status == "ignored" ->
                # Calculated how long it has been since they last requested
                inserted_at = last.inserted_at |> DateTime.from_naive!("Etc/UTC")
                diff = DateTime.diff(DateTime.utc_now, inserted_at, :second)
                rem = 60 * 24 * 60 * 60 - diff
                cond do
                  (diff / 60 / 60 / 24) < 60 ->
                    conn
                    |> put_status(:bad_request)
                    |> render(Thegm.ErrorView, "error.json", errors: ["Must wait to request again", "seconds: " <> rem])
                  true ->
                    case Repo.insert(join_changeset) do
                      {:ok, _} ->
                        send_resp(conn, :created, "")
                      {:error, resp} ->
                        error_list = Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end)
                        conn
                        |> put_status(:bad_request)
                        |> render(Thegm.ErrorView, "error.json", errors: error_list)
                    end
                end
              # User was blocked, error
              last.status == "blocked" ->
                conn
                |> put_status(:unprocessable_entity)
                |> render(Thegm.ErrorView, "error.json", errors: ["There was an issue processing your request to join this group"])
              # User was previously accepted but is no longer part of group, allow
              last.status == "accepted" ->
                case Repo.insert(join_changeset) do
                  {:ok, _} ->
                    send_resp(conn, :created, "")
                  {:error, resp} ->
                    error_list = Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end)
                    conn
                    |> put_status(:bad_request)
                    |> render(Thegm.ErrorView, "error.json", errors: error_list)
                end
            end
        end
      # User is already part of the group
      _ ->
        conn
        |> put_status(:conflict)
        |> render(Thegm.ErrorView, "error.json", errors: ["User is already a member of the group"])
    end
  end

  def update(conn, %{"group_id" => group_id, "status" => status}) do

  end

  def index(conn, %{"group_id" => group_id}) do

  end
end
