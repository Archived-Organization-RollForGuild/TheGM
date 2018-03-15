defmodule Thegm.UniqueController do
  use Thegm.Web, :controller

  def show(conn, %{"email" => email}) do
    cond do
      Regex.match?(~r/@/, email) ->
        case Repo.one(from u in Thegm.Users, where: u.email == ^email) do
          nil ->
            send_resp(conn, :no_content, "")
          _ ->
            send_resp(conn, :conflict, "")
        end
      true ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["email: must be valid email address"])
    end
  end

  def show(conn, %{"username" => username}) do
    cond do
      Regex.match?(~r/^[a-zA-Z0-9\s'_-]+$/, username) ->
        case Repo.one(from u in Thegm.Users, where: u.username == ^username ) do
          nil ->
            send_resp(conn, :no_content, "")
          _ ->
            send_resp(conn, :conflict, "")
        end
      true ->
        conn
        |> put_status (:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["username: invalid format"])
  end
end
