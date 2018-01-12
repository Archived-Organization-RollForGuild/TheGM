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

  def delete(conn, %{}) do
    conn
    |> put_status(:bad_request)
    |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `users` data type"])
  end
end
