defmodule Thegm.Router do
  use Thegm.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Thegm do
    pipe_through :api

    post "/betasub", BetasubController, :create
    get "/rolldice", RollDiceController, :index
    post "/register", UsersController, :create
    #get "/users/:username", UsersController, :show
    get "/users", UsersController, :index
    post "/login", SessionsController, :create
    post "/logout", SessionsController, :delete
  end
end
