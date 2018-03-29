defmodule Thegm.UserGamesController do
  use Thegm.Web, :controller

  alias Thegm.UserGames
  alias Thegm.Users
  alias Ecto.Multi

  def index(conn, params) do
    case read_params(params) do
      {:ok, settings} ->
        case Repo.one(from ug in UserGames, where: ug.users_id == ^settings.users_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["User Games not found"])
          _ ->
            # Get total in search
            total = Repo.one(from ug in UserGames,
                             select: count(ug.id),
                             where: ug.users_id == ^settings.users_id)

            offset = (settings.page - 1) * settings.limit
            usergames = Repo.all(
                           from ug in UserGames,
                           where: ug.users_id == ^settings.users_id,
                           order_by: [desc: ug.inserted_at],
                           limit: ^settings.limit,
                           offset: ^offset) |> Repo.preload(:games)
            meta = %{total: total, limit: settings.limit, offset: offset, count: length(usergames)}

            conn
            |> put_status(:ok)
            |> render("index.json", usergames: usergames, meta: meta)
        end
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView,
             "error.json",
             errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> v end))
    end
  end

  def create(conn, %{"users_id" => users_id, "data" => usergames}) do
    current_user_id = conn.assigns[:current_user].id

    cond do
      users_id !== current_user_id ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["You do not have permission to add games"])

      true ->
        invalid_items = Enum.reject(usergames, fn x -> x["type"] == "user-games" end)

        unless length(invalid_items) > 0 do
          usergames = Enum.map(usergames, fn (usergame) ->
            %{
              id: UUID.uuid4,
              users_id: users_id,
              games_id: usergame["id"],
              field: usergame["field"],
              inserted_at: NaiveDateTime.utc_now(),
              updated_at: NaiveDateTime.utc_now()
            }
          end)

          case Repo.insert_all(UserGames, usergames, [on_conflict: :nothing]) do
            {_, nil} ->
              send_resp(conn, :no_content, "")
            {:error, changeset} ->
              conn
              |> put_status(:internal_server_error)
              |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
          end
        else
          conn
          |> put_status(:bad_request)
          |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `user-games` data type"])
        end
    end
  end

  def update(conn, %{"users_id" => users_id, "data" => usergames}) do
    current_user_id = conn.assigns[:current_user].id

    cond do
      current_user_id !== users_id ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["You do not have permission to modify games"])

      true ->
        invalid_items = Enum.reject(usergames, fn x -> x["type"] == "user-games" end)

        unless length(invalid_items) > 0 do
          usergames = Enum.map(usergames, fn (usergame) ->
            %{
              id: UUID.uuid4,
              users_id: users_id,
              games_id: usergame["id"],
              field: usergame["field"],
              inserted_at: NaiveDateTime.utc_now(),
              updated_at: NaiveDateTime.utc_now()
            }
          end)

          transaction = Multi.new
          |> Multi.delete_all(:remove_usergames, from(ug in UserGames, where: ug.users_id == ^users_id))
          |> Multi.insert_all(:add_usergames, UserGames, usergames, [on_conflict: :nothing])

          case Repo.transaction(transaction) do
            {:ok, _} ->
              send_resp(conn, :no_content, "")
            {:error, _, changeset, _} ->
              conn
              |> put_status(:internal_server_error)
              |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
          end
        else
          conn
          |> put_status(:bad_request)
          |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `user-games` data type"])
        end
    end
  end

  def delete(conn, %{"users_id" => users_id, "id" => games_id}) do
    current_user_id = conn.assigns[:current_user].id

    case Repo.get(Users, users_id) |> Repo.preload(:user_games) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["User not found"])
      user ->
        target_game = Enum.find(user.user_games, fn x -> x.games_id == games_id end)

        cond do
          current_user_id !== users_id ->
            conn
            |> put_status(:forbidden)
            |> render(Thegm.ErrorView, "error.json", errors: ["You do not have permission to remove this game"])

          target_game == nil ->
            send_resp(conn, :no_content, "")

          true ->
            case Repo.delete(target_game) do
              {:ok, _} ->
                send_resp(conn, :no_content, "")
              {:error, changeset} ->
                conn
                |> put_status(:internal_server_error)
                |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
            end
        end
    end
  end

  defp read_params(params) do
    errors = []

    # set page
    {users_id, errors} = case params["users_id"] do
      nil ->
        errors = errors ++ ["users_id": "must be supplied"]
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
        {:ok, %{users_id: users_id, page: page, limit: limit}}
    end
    resp
  end
end
