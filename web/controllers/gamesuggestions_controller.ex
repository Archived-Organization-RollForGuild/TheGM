defmodule Thegm.GameSuggestionsController do
  use Thegm.Web, :controller
  alias Thegm.GameSuggestions

  def create(conn, %{"users_id" => users_id, "data" => %{"type" => type, "attributes" => params}}) do
    curr_users_id = conn.assigns[:current_user].id
    cond do
      users_id != curr_users_id ->
        conn
        |> put_status(:forbidden)
        |> render(Thegm.ErrorView, "error.json", errors: ["You cannot summit a game suggestion for a different user"])

      type == "game-suggestions" ->
        game_changeset = Thegm.GameSuggestions.create_changeset(%Thegm.GameSuggestions{}, Map.merge(params, %{"users_id" => users_id}))
        case Repo.insert(game_changeset) do
          {:ok, game_suggestion} ->
            conn
            |> put_status(:created)
            |> render(Thegm.GameSuggestionsView, "show.json", game_suggestion: game_suggestion)

          {:error, resp} ->
            conn
            |> put_status(:bad_request)
            |> render(Thegm.ErrorView, "error.json", errors: Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
        end

      true ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non 'games' type"])
    end
  end

  def create(conn, %{"groups_id" => groups_id, "data" => %{"type" => type, "attributes" => params}}) do
    users_id = conn.assigns[:current_user].id

    # Ensure user is a member and admin of the group
    case Thegm.GroupMembers.is_member_and_admin?(users_id, groups_id) do
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: error)

      {:ok, _} ->
        if  type != "game-suggestions" do
          conn
          |> put_status(:bad_request)
          |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non 'games' type"])
        else
          game_changeset = Thegm.GameSuggestions.create_changeset(%Thegm.GameSuggestions{}, Map.merge(params, %{"users_id" => users_id, "groups_id" => groups_id}))
          insert_game_suggestion_changeset(conn, game_changeset)
        end
    end
  end

  def insert_game_suggestion_changeset(conn, game_changeset) do
    case Repo.insert(game_changeset) do
      {:ok, game_suggestion} ->
        conn
        |> put_status(:created)
        |> render(Thegm.GameSuggestionsView, "show.json", game_suggestion: game_suggestion)

      {:error, resp} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
    end
  end

  def index(conn, params = %{"groups_id" => groups_id}) do
    case Thegm.ReadPagination.read_pagination_params(params) do
      {:ok, settings} ->
        total = Repo.one(
          from gs in GameSuggestions,
          select: count(gs.id),
          where: gs.groups_id == ^groups_id
        )

        # do the search
        games = Repo.all(
          from gs in GameSuggestions,
          where: gs.groups_id == ^groups_id,
          limit: ^settings.limit,
          offset: ^settings.offset
        )

        meta = %{total: total, limit: settings.limit, offset: settings.offset, count: length(games)}

        conn
        |> put_status(:ok)
        |> render("index.json", game_suggestions: games, meta: meta)
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
    end
  end

  def index(conn, params = %{"users_id" => users_id}) do
    case Thegm.ReadPagination.read_pagination_params(params) do
      {:ok, settings} ->
        total = Repo.one(
          from gs in GameSuggestions,
          select: count(gs.id),
          where: gs.users_id == ^users_id and is_nil(gs.groups_id)
        )

        # do the search
        games = Repo.all(
          from gs in GameSuggestions,
          where: gs.users_id == ^users_id and is_nil(gs.groups_id),
          limit: ^settings.limit,
          offset: ^settings.offset
        )

        meta = %{total: total, limit: settings.limit, offset: settings.offset, count: length(games)}

        conn
        |> put_status(:ok)
        |> render("index.json", game_suggestions: games, meta: meta)
      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
    end
  end

  def show(conn, %{"groups_id" => groups_id, "id" => game_suggestions_id}) do
    case Repo.one(from gs in GameSuggestions, where: gs.groups_id == ^groups_id and gs.id == ^game_suggestions_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["No game suggestion with the specified and id and groups_id cobination found"])
      game ->
        conn
        |> put_status(:ok)
        |> render("show.json", game_suggestion: game)
    end
  end

  def show(conn, %{"users_id" => users_id, "id" => game_suggestions_id}) do
    case Repo.one(from gs in GameSuggestions, where: gs.users_id == ^users_id and gs.id == ^game_suggestions_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["No game suggestion with the specified and id and users_id cobination found"])
      game ->
        conn
        |> put_status(:ok)
        |> render("show.json", game_suggestion: game)
    end
  end
end
