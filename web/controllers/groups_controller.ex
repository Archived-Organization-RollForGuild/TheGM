defmodule Thegm.GroupsController do
  use Thegm.Web, :controller

  alias Thegm.Groups
  alias Ecto.Multi

  def create(conn, %{"data" => %{"attributes" => params, "type" => type}}) do
    case {type, params} do
      {"group", params} ->
        group_changeset = Groups.create_changeset(%Groups{}, params)
        multi =
          Multi.new
          |> Multi.insert(:groups, group_changeset)
          |> Multi.run(:group_members, fn %{groups: group} ->
            member_changeset =
              %Thegm.GroupMembers{groups_id: group.id}
              |> Thegm.GroupMembers.changeset(%{role: "admin", users_id: conn.assigns[:current_user].id})
            Repo.insert(member_changeset)
          end)

        case Repo.transaction(multi) do
          {:ok, result} ->
            conn
            |> put_status(:created)
            |> render(Thegm.GroupsView, "memberof.json", group: result.groups)
          {:error, :groups, changeset, errors} ->
            IO.inspect changeset
            IO.inspect errors
            conn
            |> put_status(:unprocessable_entity)
            |> render(Thegm.ErrorView, "error.json", errors: ["Bad group"])
          {:error, :group_members, changeset, errors} ->
            IO.inspect changeset
            IO.inspect errors
            conn
            |> put_status(:unprocessable_entity)
            |> render(Thegm.ErrorView, "error.json", errors: ["Bad member"])
          catch_all ->
            IO.inspect catch_all
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
