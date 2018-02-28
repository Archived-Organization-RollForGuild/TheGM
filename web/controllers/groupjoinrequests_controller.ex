defmodule Thegm.GroupJoinRequestsController do
  use Thegm.Web, :controller

  alias Thegm.GroupJoinRequests
  alias Ecto.Multi

  # NOTE: This can probably be made prettier somehow, it isn't very readable currently - Quigley
  def create(conn, %{"group_id" => group_id}) do
    user_id = conn.assigns[:current_user].id
    case Repo.one(from b in Thegm.GroupBlockedUsers, where: b.group_id == ^group_id and b.user_id == ^user_id and b.rescinded == false) do
      nil ->
        case Repo.all(from m in Thegm.GroupMembers, where: m.groups_id == ^group_id and m.users_id == ^user_id) do
          # confirmed user is not already part of group
          [] ->
            join_changeset = GroupJoinRequests.create_changeset(%GroupJoinRequests{}, %{group_id: group_id, user_id: user_id})
            case Repo.all(from gj in GroupJoinRequests, where: gj.group_id == ^group_id and gj.user_id == ^user_id, order_by: [desc: gj.inserted_at]) do
              # user has not previously requested to join the group, commit request
              [] ->
                case Repo.insert(join_changeset) do
                  {:ok, _} ->
                    send_resp(conn, :ok, "")
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
                    # if it has been less than 60 days since they last requested
                    if (diff / 60 / 60 / 24) < 60  do
                      rem = 60 * 24 * 60 * 60 - diff
                      conn
                      |> put_status(:bad_request)
                      |> render(Thegm.ErrorView, "error.json", errors: ["Must wait to request again", "seconds: " <> rem])
                    else
                      case Repo.insert(join_changeset) do
                        {:ok, _} ->
                          send_resp(conn, :ok, "")
                        {:error, resp} ->
                          error_list = Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end)
                          conn
                          |> put_status(:bad_request)
                          |> render(Thegm.ErrorView, "error.json", errors: error_list)
                      end
                    end
                  # User was previously accepted but is no longer part of group, allow
                  last.status == "accepted" ->
                    case Repo.insert(join_changeset) do
                      {:ok, _} ->
                        send_resp(conn, :ok, "")
                      {:error, resp} ->
                        error_list = Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end)
                        conn
                        |> put_status(:bad_request)
                        |> render(Thegm.ErrorView, "error.json", errors: error_list)
                    end
                  true ->
                    conn
                    |> put_status(:internal_server_error)
                    |> render(Thegm.ErrorView, "error.json", errors: ["Previous request is in an unrecognized state"])
                end
            end
          # User is already part of the group
          _ ->
            conn
            |> put_status(:conflict)
            |> render(Thegm.ErrorView, "error.json", errors: ["User is already a member of the group"])
        end
      _ ->
        conn
        |> put_status(:gone)
        |> render(Thegm.ErrorView, "error.json", errors: ["The group you are requesting to join is gone"])
    end
  end

  def update(conn, %{"group_id" => group_id, "id" => request_user_id, "data" => %{"attributes" => params, "type" => type}}) do
    admin_user_id = conn.assigns[:current_user].id
    member = Repo.one(from gm in Thegm.GroupMembers, where: gm.groups_id == ^group_id and gm.users_id == ^admin_user_id)
    cond do
      member.role == "admin" ->
        case type do
          "join-requests" ->
            case Repo.one(from gjr in GroupJoinRequests, where: gjr.user_id == ^request_user_id and gjr.group_id == ^group_id and gjr.pending == true) do
              nil ->
                conn
                |> put_status(:gone)
                |> render(Thegm.ErrorView, "error.json", errors: ["gone: That join request is gone"])
              join_request ->
                cond do
                  Map.has_key?(params, "status") ->
                    cond do
                      params["status"] == "accepted" ->
                        request_changeset = GroupJoinRequests.update_changeset(join_request, params)
                        member_changeset = Thegm.GroupMembers.create_changeset(%Thegm.GroupMembers{}, %{:groups_id => group_id, :users_id => request_user_id, :role => "member"})
                        multi =
                          Multi.new
                          |> Multi.update(:group_join_requests, request_changeset)
                          |> Multi.insert(:group_members, member_changeset)

                        case Repo.transaction(multi) do
                          {:ok, _} ->
                            send_resp(conn, :no_content, "")
                          {:error, :group_join_request, changeset, %{}} ->
                            conn
                            |> put_status(:unprocessable_entity)
                            |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                          {:error, :group_members, changeset, %{}} ->
                            conn
                            |> put_status(:unprocessable_entity)
                            |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                        end
                      params["status"] == "ingored" ->
                        request_changeset = GroupJoinRequests.update_changeset(join_request, params)
                        case Repo.update(request_changeset) do
                          {:ok, _} ->
                            send_resp(conn, :no_content, "")
                          {:error, error} ->
                            conn
                            |> put_status(:internal_server_error)
                            |> render(Thegm.ErrorView, "error.json", errors: Enum.map(error.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                        end
                      params["status"] == "blocked" ->
                        request_changeset = GroupJoinRequests.update_changeset(join_request, %{:status => "ignored"})
                        case Repo.update(request_changeset) do
                          {:ok, _} ->
                            send_resp(conn, :no_content, "")
                          {:error, error} ->
                            conn
                            |> put_status(:internal_server_error)
                            |> render(Thegm.ErrorView, "error.json", errors: Enum.map(error.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                        end
                        # TODO the blocking part, probably should be a multi
                    end
                  true ->
                    conn
                    |> put_status(:bad_request)
                    |> render(Thegm.ErrorView, "error.json", errors: ["body.data.attributes: The key 'status' is required"])
                end
            end
          _ ->
            conn
            |> put_status(:bad_request)
            |> render(Thegm.ErrorView, "error.json", errors: ["type: Expected 'join-requests', received '" <> type <>"'"])
        end
      true ->
        conn
        |> put_status(:forbidden)
        |> render(Thegm.ErrorView, "error.json", erros: ["role: You must be an admin of the group to take this action"])
    end
  end

  def index(conn, params) do
    user_id = conn.assigns[:current_user].id
    case read_params(params) do
      {:ok, settings} ->
        case Repo.one(from gm in Thegm.GroupMembers, where: gm.groups_id == ^settings.group_id and gm.users_id == ^user_id and gm.role == "admin") do
          nil ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["role: Must be an admin of the group to view join requests"])
          _ ->
            # Get total in search
            total = Repo.one(from gjr in GroupJoinRequests,
            select: count(gjr.id),
            where: gjr.group_id == ^settings.group_id and is_nil(gjr.status))

            offset = (settings.page - 1) * settings.limit
            gjrs = Repo.all(
              from gjr in GroupJoinRequests,
              where: gjr.group_id == ^settings.group_id and is_nil(gjr.status),
              order_by: [desc: gjr.inserted_at],
              limit: ^settings.limit,
              offset: ^offset) |> Repo.preload(:user)
            IO.inspect gjrs
            meta = %{total: total, limit: settings.limit, offset: offset, count: length(gjrs)}

            conn
            |> put_status(:ok)
            |> render("show.json", requests: gjrs, meta: meta)
        end
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView,
          "error.json",
          errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> v end))
    end
  end

  defp read_params(params) do
    errors = []

    # set page
    {group_id, errors} = case params["group_id"] do
      nil ->
        errors = errors ++ ["group_id": "must be supplied"]
        {nil, errors}
      temp ->
        {temp, errors}
    end

    # set page
    {page, errors} = case params["page"] do
      nil ->
        page = 1
        {page, errors}
      temp ->
        {page, _} = Integer.parse(temp)
        errors = if page < 1 do
          errors ++ [page: "Must be a positive integer"]
        end
        {page, errors}
    end

    {limit, errors} = case params["limit"] do
      nil ->
        limit = 100
        {limit, errors}
      temp ->
        {limit, _} = Integer.parse(temp)
        errors = if limit < 1 do
          errors ++ [limit: "Must be at integer greater than 0"]
        end
        {limit, errors}
    end

    resp = cond do
      length(errors) > 0 ->
        {:error, errors}
      true ->
        {:ok, %{group_id: group_id, page: page, limit: limit}}
    end
    resp
  end
end
