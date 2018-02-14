defmodule Thegm.PasswordResetsController do
  use Thegm.Web, :controller

  alias Thegm.PasswordResets
  alias Thegm.Users

  def create(conn, %{"data" => %{"attributes" => params, "type" => type}}) do
    case {type, params} do
      {"reset", params} ->
        user = Repo.get_by(Users, email: params["email"])

        cond do
          user ->
            Repo.delete_all(PasswordResets, [user_id: user.id, used: false])
            changeset = PasswordResets.changeset(%PasswordResets{},%{"used" => false, "user_id" => user.id})

            case Repo.insert(changeset) do
              {:ok, reset} ->
                Thegm.Mailgun.email_password_reset(params["email"], reset.id)
                |> Thegm.Mailer.deliver_now
                send_resp(conn, :created, "")
            end

          true ->
            send_resp(conn, :created, "")

        end

      _ ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `reset` data type"])
    end
  end

  def update(conn, %{"id" => id, "data" => %{"attributes" => params}}) do
    case Repo.get(PasswordResets, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Invalid password reset"])
      resp ->
        cond do
          resp.used == false && NaiveDateTime.diff(NaiveDateTime.utc_now(), resp.inserted_at) ->
            code = PasswordResets.changeset(resp, %{used: true})
            case Repo.update(code) do
              {:ok, updated_code} ->
                case Repo.get(Thegm.Users, updated_code.user_id) do
                  nil ->
                    conn
                    |> put_status(:not_found)
                    |> render(Thegm.ErrorView, "error.json", errors: ["Unable to locate user"])
                  user ->
                    user = Thegm.Users.changeset(user, %{password: params["password"]})
                    case Repo.update(user) do
                      {:ok, _} ->
                        send_resp(conn, :ok, "")
                      {:error, user} ->
                        conn
                        |> put_status(:bad_request)
                        |> render(Thegm.ErrorView, "error.json", errors: Enum.map(user.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                    end
                end
              {:error, updated_code} ->
                conn
                |> put_status(:bad_request)
                |> render(Thegm.ErrorView, "error.json", errors: Enum.map(updated_code.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
            end

          true ->
            conn
            |> put_status(:not_found)
            |> render(Thegm.ErrorView, "error.json", errors: ["Invalid password reset"])

        end
    end
  end
end
