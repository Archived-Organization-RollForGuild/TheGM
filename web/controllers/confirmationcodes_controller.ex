defmodule Thegm.ConfirmationCodesController do
  use Thegm.Web, :controller

  alias Thegm.ConfirmationCodes

  def create(user_id, email) do
    changeset = ConfirmationCodes.changeset(%ConfirmationCodes{},%{"used" => false, "user_id" => user_id})
    case Repo.insert(changeset) do
      {:ok, params} ->
        Thegm.Emails.email_confirmation_email(email, params.id)
        |> Thegm.Mailer.deliver_now
    end
  end

  def delete(conn, %{"id" => id}) do
    resp = Repo.get(ConfirmationCodes, id)
    code = ConfirmationCodes.changeset(resp, %{used: true})
    case Repo.update(code) do
      {:ok, resp2} ->
        resp3 = Repo.get(Thegm.Users, resp2.user_id)
        user = Thegm.Users.changeset(resp3, %{active: true})
        case Repo.update(user) do
          {:ok, resp4} ->
            session_changeset = Thegm.Sessions.create_changeset(%Thegm.Sessions{}, %{user_id: resp4.id})
            {:ok, session} = Repo.insert(session_changeset)
            conn
            |> put_status(:created)
            |> render(Thegm.SessionsView, "show.json", session: session)
        end
    end
    conn
    |> put_status(:bad_request)
    |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `users` data type"])
  end
end
