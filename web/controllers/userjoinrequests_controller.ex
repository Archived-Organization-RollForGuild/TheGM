defmodule Thegm.UserJoinRequestsController do
  @moduledoc "Controller responsible for handling user join requests"

  use Thegm.Web, :controller

  alias Thegm.UserJoinRequests

  def index(conn, %{"user_id" => user_id}) do
    
  end

  def delete(conn, %{"user_id" => user_id, "request_id" => request_id}) do

  end
end
