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
    case {type, params} do
      {"users", params} ->
        user_changeset = Users.create_changeset(%Users{}, params)
        multi = Multi.new
          |> Multi.insert(:users, user_changeset)
          |> Multi.run(:preferences, fn %{users: user} ->
            preferences_changeset = Thegm.Preferences.create_changeset(%Thegm.Preferences{}, %{"users_id" => user.id})
            Repo.insert(preferences_changeset)
          end)

        case Repo.transaction(multi) do
          {:ok, result} ->
            user = result.users
            Thegm.ConfirmationCodesController.new(user.id, user.email)
            Thegm.Mailchimp.subscribe_new_user(user.email)

            send_resp(conn, :created, "")
          {:error, _, changeset, %{}} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
        end
      _ ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `user` data type"])
    end
  end

  def update(conn, %{"id" => users_id, "data" => %{"attributes" => params, "type" => type}}) do
    current_user = conn.assigns[:current_user]
    cond do
      type == "users" ->
        case Repo.get(Users, users_id) |> Repo.preload([{:user_games, :games}, {:group_members, :groups}, :preferences]) do
          nil ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `username` was not found"])
          user ->
            cond do
              current_user.id == users_id ->
                user = Users.unrestricted_changeset(user, params)

                if Map.has_key?(params, "email") do
                  update_email(current_user, params["email"])
                end

                case Repo.update(user) do
                  {:ok, result} ->
                    conn
                    |> put_status(:ok)
                    |> render("private.json", user: result)
                  {:error, changeset} ->
                    conn
                    |> put_status(:unprocessable_entity)
                    |> render(Thegm.ErrorView, "error.json", errors: Enum.map(changeset.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                end
              true ->
                conn
                |> put_status(:forbidden)
                |> render(Thegm.ErrorView, "error.json", errors: ["You do not have privileges to edit this account"])
            end
        end
      true ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `user` data type"])
    end
  end

  def show(conn, %{"id" => users_id}) do
    current_user_id = conn.assigns[:current_user].id

    case Repo.get(Users, users_id) |> Repo.preload([{:user_games, :games}, {:group_members, :groups}, :preferences]) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["A user with the specified `username` was not found"])
      user ->
      cond do
        current_user_id == users_id ->
          render conn, "private.json", user: user
        true ->
          render conn, "public.json", user: user
      end
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
end
# credo:disable-for-this-file
