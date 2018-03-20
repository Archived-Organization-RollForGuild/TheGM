defmodule Thegm.EmailChangeController do
  use Thegm.Web, :controller

  alias Thegm.EmailChangeCodes

  def update(conn, %{"id" => id, "response" => "accept"}) do
    case Repo.get(EmailChangeCodes, id) do
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
          code = EmailChangeCodes.changeset(resp, %{used: true})
          case Repo.update(code) do
            {:ok, updated_code} ->
              case Repo.get(Thegm.Users, resp.users_id) |> Repo.preload([{:group_members, :groups}]) do
                nil ->
                  conn
                  |> put_status(:not_found)
                  |> render(Thegm.ErrorView, "error.json", errors: ["Unable to locate user"])
                user_response ->
                  user = Thegm.Users.changeset(user_response, %{email: resp.email})
                  case Repo.update(user) do
                    {:ok, updated_user} ->
                      conn
                      |> put_status(:ok)
                      |> render(Thegm.UsersView, "private.json", user: updated_user)
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

  def update(conn, %{"id" => id, "response" => "reject"}) do
    case Repo.get(EmailChangeCodes, id) do
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
          code = EmailChangeCodes.changeset(resp, %{used: true})
          case Repo.update(code) do
            {:ok, updated_code} ->
              case Repo.get(Thegm.Users, resp.users_id) |> Repo.preload([{:group_members, :groups}]) do
                nil ->
                  conn
                  |> put_status(:not_found)
                  |> render(Thegm.ErrorView, "error.json", errors: ["Unable to locate user"])
                user_response ->
                  user = Thegm.Users.changeset(user_response, %{email: resp.old_email})
                  case Repo.update(user) do
                    {:ok, updated_user} ->
                      conn
                      |> put_status(:ok)
                      |> render(Thegm.UsersView, "private.json", user: updated_user)
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
