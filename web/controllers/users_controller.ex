defmodule Thegm.UsersController do
  use Thegm.Web, :controller

  alias Thegm.Users

  def index(conn, _params) do
    users = Repo.all(Users)
    render conn, "index.json", users: users
  end

  def create(conn, %{"data" => params}) do
    changeset = Users.changeset(%Users{}, params)

    case Repo.insert(changeset) do
      {:ok, _resp} ->
        users = Repo.all(Users)
        render conn, "index.json", users: users
    end
  end
end
