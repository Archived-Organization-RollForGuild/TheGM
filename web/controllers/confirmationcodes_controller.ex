defmodule Thegm.ConfirmationCodesController do
  use Thegm.Web, :controller

  alias Thegm.ConfirmationCodes

  # TODO: Once logging is implemented, add case for errors
  def new(users_id, email) do
    changeset = ConfirmationCodes.changeset(%ConfirmationCodes{},%{"used" => false, "users_id" => users_id})
    case Repo.insert(changeset) do
      {:ok, params} ->
        Thegm.Mailgun.email_confirmation_email(email, params.id)
        |> Thegm.Mailer.deliver_now
    end
  end

  # It's not really a create, but oh fucking well. It's a post, so it's a create, don't question it.
  def create(conn, %{"id" => id}) do
    case Repo.get(ConfirmationCodes, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Thegm.ErrorView, "error.json", errors: ["Invalid confirmation code"])
      resp ->
        if resp.used do
          conn
          |> put_status(:forbidden)
          |> render(Thegm.ErrorView, "error.json", errors: ["Code already used"])
        else
          code = ConfirmationCodes.changeset(resp, %{used: true})
          case Repo.update(code) do
            {:ok, resp2} ->
              case Repo.get(Thegm.Users, resp2.users_id) do
                nil ->
                  conn
                  |> put_status(:not_found)
                  |> render(Thegm.ErrorView, "error.json", errors: ["Unable to locate user"])
                resp3 ->
                  user = Thegm.Users.changeset(resp3, %{active: true})
                  case Repo.update(user) do
                    {:ok, resp4} ->
                      session_changeset = Thegm.Sessions.create_changeset(%Thegm.Sessions{}, %{users_id: resp4.id})
                      case Repo.insert(session_changeset) do
                        {:ok, session} ->
                          conn
                          |> put_status(:ok)
                          |> render(Thegm.SessionsView, "show.json", session: session)
                        {:error, resp5} ->
                          conn
                          |> put_status(:bad_request)
                          |> render(Thegm.ErrorView, "error.json", errors: Enum.map(resp5.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                      end
                    {:error, resp4} ->
                      conn
                      |> put_status(:bad_request)
                      |> render(Thegm.ErrorView, "error.json", errors: Enum.map(resp4.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
                  end
              end
            {:error, resp2} ->
              conn
              |> put_status(:bad_request)
              |> render(Thegm.ErrorView, "error.json", errors: Enum.map(resp2.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end))
          end
        end
    end
  end
end
