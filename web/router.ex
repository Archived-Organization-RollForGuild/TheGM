defmodule Thegm.Router do
  use Thegm.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Thegm do
    pipe_through :api
  end
end
