defmodule Thegm.Router do
  use Thegm.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug Thegm.AuthenticateUser
  end

  scope "/", Thegm do
    pipe_through [:api, :auth]

    post "/betasub", BetasubController, :create
    get "/rolldice", RollDiceController, :index
    #get "/users/:username", UsersController, :show
    get "/users", UsersController, :index
    post "/logout", SessionsController, :delete
  end

  scope "/", Thegm do
    pipe_through :api
    post "/register", UsersController, :create
    post "/login", SessionsController, :create
  end
end
