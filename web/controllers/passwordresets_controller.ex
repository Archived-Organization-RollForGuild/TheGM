defmodule Thegm.PasswordResetsController do
  @moduledoc "Controller responsible for handling password resets"

  use Thegm.Web, :controller

  alias Thegm.PasswordResets
  alias Thegm.Users

  def create(conn, %{"data" => %{"attributes" => params, "type" => type}}) do
    case {type, params} do
      {"resets", params} ->
        user = Repo.get_by(Users, email: params["email"])

        if user do
          Repo.delete_all(PasswordResets, [user_id: user.id, used: false])
          changeset = PasswordResets.changeset(%PasswordResets{}, %{"used" => false, "user_id" => user.id})

          case Repo.insert(changeset) do
            {:ok, reset} ->
              Thegm.Mailgun.email_password_reset(params["email"], reset.id)
              |> Thegm.Mailer.deliver_now
              send_resp(conn, :created, "")
          end

        else
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
        if resp.used == false && NaiveDateTime.diff(NaiveDateTime.utc_now(), resp.inserted_at) do
          code = PasswordResets.changeset(resp, %{used: true})
          case Repo.update(code) do
            {:ok, updated_code} ->
              new_password = params["password"]
              update_password(conn, user, new_password)
            {:error, updated_code} ->
              conn
              |> put_status(:bad_request)
              |> render(Thegm.ErrorView, "error.json", errors: Enum.map(updated_code.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
          end

        else
          conn
          |> put_status(:not_found)
          |> render(Thegm.ErrorView, "error.json", errors: ["Invalid password reset"])
      end
    end
  end

  def update_password(conn, user, password) do
    case Repo.get(Thegm.Users, user.id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Unable to locate user"])
      user ->
        user = Thegm.Users.changeset(user, %{password: password})
        case Repo.update(user) do
          {:ok, _} ->
            send_resp(conn, :ok, "")
          {:error, user} ->
            conn
            |> put_status(:bad_request)
            |> render(Thegm.ErrorView, "error.json", errors: Enum.map(user.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
        end
    end
  end
end
