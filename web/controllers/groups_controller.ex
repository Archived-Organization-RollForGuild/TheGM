defmodule Thegm.GroupsController do
  use Thegm.Web, :controller

  alias Thegm.Groups

  def create(conn, %{"data" => %{"attributes" => params, "type" => type}}) do
    case {type, params} do
      {"group", params} ->
        changeset = Groups.create_changeset(%Groups{}, params)
        
        case Repo.insert(changeset) do
          {:ok, resp} ->
            send_resp(conn, :created, "")
          {:error, resp} ->
            error_list = Enum.map(resp.errors, fn {k, v} -> Atom.to_string(k) <> ": " <> elem(v, 0) end)
            conn
            |> put_status(:bad_request)
            |> render(Thegm.ErrorView, "error.json", errors: error_list)
        end
      _ ->
        conn
        |> put_status(:bad_request)
        |> render(Thegm.ErrorView, "error.json", errors: ["Posted a non `group` data type"])
    end
  end

  def delete(conn, params) do

  end

  def index(conn, params) do

  end

  def show(conn, params) do

  end

  def update(conn, params) do

  end
end
