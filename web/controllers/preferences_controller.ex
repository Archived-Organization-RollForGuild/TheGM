defmodule Thegm.PreferencesController do
  use Thegm.Web, :controller

  alias Thegm.{Preferences}

  def new(users_id) do
    changeset = Preferences.changeset(%Preferences{}, %{"user_id" => users_id})
    Repo.insert(changeset)
  end

  def update(conn, %{"users_id" => users_id, "data" => %{"attributes" => params, "type" => type}}) do
    current_user_id = conn.assigns[:current_user].id

    case Repo.one(from p in Preferences, where: p.users_id == ^users_id)
    |> Repo.preload([:users]) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `id` was not found"])
      preferences ->
        if type !== "preferences" do
          conn
          |> put_status(:bad_request)
          |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `preferences` data type"])
        end

        if current_user_id == users_id do
          preferences_changeset = Preferences.changeset(preferences, params)

          case Repo.update(preferences_changeset) do
            {:ok, result} ->
              result
              |> Repo.preload([:users])

              conn
              |> put_status(:ok)
              |> render("show.json", preferences: result)
            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> render(Thegm.ErrorView, "error.json",
              errors: Enum.map(changeset.errors, fn {k, v} ->
                Atom.to_string(k) <> ": " <> elem(v, 0) end))
          end
        else
          conn
          |> put_status(:not_found)
          |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `id` was not found"])
        end
    end
  end

  def show(conn, %{"users_id" => users_id}) do
    current_user_id = conn.assigns[:current_user].id

    case Repo.one(from p in Preferences, where: p.users_id == ^users_id)
    |> Repo.preload([:users]) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `id` was not found"])
      preferences ->
        if current_user_id == users_id do
          conn
          |> put_status(:ok)
          |> render("show.json", preferences: preferences)
        else
          conn
          |> put_status(:not_found)
          |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `id` was not found"])
        end
    end
  end
end
