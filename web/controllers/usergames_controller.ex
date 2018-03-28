defmodule Thegm.UserGamesController do
  use Thegm.Web, :controller

  alias Thegm.UserGames
  alias Thegm.Users
  alias Ecto.Multi

  def index(conn, %{"users_id" => users_id}) do
    case Repo.all(from ug in UserGames, where: ug.users_id == ^users_id) |> Repo.preload(:games) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["User games could not be located"])
      resp ->
        conn
        |> put_status(:ok)
        |> render("index.json", usergames: resp)
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
end
