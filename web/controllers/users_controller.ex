defmodule Thegm.UsersController do
  use Thegm.Web, :controller

  alias Thegm.Users
  alias Thegm.EmailChangeCodes
  alias Ecto.Multi

  def index(conn, %{}) do
    conn
    |> put_status(:not_implemented)
    |> render(Thegm.ErrorView, "error.json", errors: ["This endpoint is not implemented"])
  end

  def create(conn, %{"data" => %{"attributes" => params, "type" => type}}) do
    with {:ok, _} <- Thegm.Validators.validate_type(type, "users"),
      user_changeset = Users.create_changeset(%Users{}, params),
      {:ok, multi} <- create_user_multi(user_changeset),
      {:ok, result} <- Repo.transaction(multi),
      {:ok, games, game_suggestions} <- Thegm.Reader.read_games_and_game_suggestions(params),
      {:ok, user_games} <- Thegm.GameCompiling.compile_game_changesets(games, :users_id, result.users.id),
      {:ok, user_game_suggestions} <- Thegm.GameCompiling.compile_game_suggestion_changesets(game_suggestions, :users_id, result.users.id) do
        # Inserting games is separate than group multi as games failing shouldn't fail user creation
        Repo.insert_all(Thegm.UserGames, user_games ++ user_game_suggestions)

        user = result.users
        Thegm.ConfirmationCodesController.new(user.id, user.email)
        Thegm.Mailchimp.subscribe_new_user(user.email)

        send_resp(conn, :created, "")
    else
      {:error, _, changeset, %{}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: [error])
    end
  end

  def update(conn, %{"id" => users_id, "data" => %{"attributes" => params, "type" => type}}) do
    current_user = conn.assigns[:current_user]
    with {:ok, _} <- Thegm.Validators.validate_type(type, "users"),
      {:ok, _} <- Thegm.Users.match_user_ids(users_id, current_user.id),
      {:ok, params_games, games_status} <- Thegm.Reader.read_games_and_status(params),
      {:ok, params_game_suggestions, game_suggestions_status} <- Thegm.Reader.read_game_suggestions_and_status(params),
      {:ok, games} <- Thegm.GameCompiling.compile_game_changesets(params_games, :users_id, current_user.id),
      {:ok, game_suggestions} <- Thegm.GameCompiling.compile_game_suggestion_changesets(params_game_suggestions, :users_id, current_user.id),
      user_changeset <- Users.changeset(current_user, params),
      {:ok, multi} <- create_update_user_with_games_list_multi(user_changeset, games_status, game_suggestions_status, games ++ game_suggestions),
      {:ok, resp} <- Repo.transaction(multi) do
        if Map.has_key?(params, "email") do
                  update_email(current_user, params["email"])
        end
        user = resp.users |> Repo.preload([{:group_members, :groups}, :preferences])
        conn
        |> put_status(:ok)
        |> render("private.json", user: user)
    else
      {:error, :not_found, error} ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: error)

      {:error, :users_dont_match, _} ->
        conn
        |> put_status(:forbidden)
        |> render(Thegm.ErrorView, "error.json", errors: ["You do not have permission to take this action"])

      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: [error])

      {:error, _, changeset, %{}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
    end
  end

  def show(conn, %{"id" => users_id}) do
    current_user_id = conn.assigns[:current_user].id
    with {:ok, user} <- Users.get_user_by_id_with_groups_and_preferences(users_id) do
      if current_user_id == users_id do
        render(conn, "private.json", user: user)
      else
        render(conn, "public.json", user: user)
      end
    else
      {:error, :not_found, error} ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: [error])
    end
  end

  def update_email(user, email) do
    changeset = EmailChangeCodes.changeset(%EmailChangeCodes{}, %{
      "used" => false,
      "users_id" => user.id,
      "email" => email,
      "old_email" => user.email
    })
    case Repo.insert(changeset) do
      {:ok, params} ->
        Thegm.Mailgun.email_change_email(email, params.id)
        |> Thegm.Mailer.deliver_now

        Thegm.Mailgun.email_rollback_email(user.email, user.username, params.id)
        |> Thegm.Mailer.deliver_now
    end
  end

  defp create_user_multi(user_changeset) do
    multi = Multi.new
      |> Multi.insert(:users, user_changeset)
      |> Multi.run(:preferences, fn %{users: user} ->
        preferences_changeset = Thegm.Preferences.create_changeset(%Thegm.Preferences{}, %{"users_id" => user.id})
        Repo.insert(preferences_changeset)
      end)

    {:ok, multi}
  end

  defp create_update_user_with_games_list_multi(user_changeset, games_status, game_suggestions_status, games_list) do
    multi = Multi.new
    |> Multi.update(:users, user_changeset)
    |> decide_update_game_removal(user_changeset, games_status, game_suggestions_status)
    |> decide_update_game_replace(games_status, game_suggestions_status, games_list)

    {:ok, multi}
  end

  # Credo considers the following funtion too complex... I disagree...
  # credo:disable-for-lines:12
  defp decide_update_game_removal(multi, user_changeset, games_status, game_suggestions_status) do
    cond do
      games_status == :replace and game_suggestions_status == :replace ->
        multi |> Multi.delete_all(:remove_user_games, from(ug in Thegm.UserGames, where:  ug.groups_id == ^user_changeset.data.id))
      games_status == :replace and game_suggestions_status == :skip ->
        multi |> Multi.delete_all(:remove_user_games, from(ug in Thegm.UserGames, where:  ug.groups_id == ^user_changeset.data.id and not is_nil(ug.games_id)))
      games_status == :skip and game_suggestions_status == :replace ->
        multi |> Multi.delete_all(:remove_user_games, from(ug in Thegm.UserGames, where: ug.groups_id == ^user_changeset.data.id and not is_nil(ug.game_suggestions_id)))
      true ->
        multi
    end
  end

  defp decide_update_game_replace(multi, games_status, game_suggestions_status, games_list) do
    if games_status == :replace or game_suggestions_status == :replace do
      multi |> Multi.insert_all(:insert_user_games, Thegm.UserGames, games_list)
    else
      multi
    end
  end
end
