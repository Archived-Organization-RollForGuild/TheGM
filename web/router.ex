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

    get "/rolldice", RollDiceController, :index
    get "/users/:user_id", UsersController, :show
    get "/users", UsersController, :index
    post "/logout", SessionsController, :delete
    resources "/groups", GroupsController, except: [:edit, :new]
    get "/groups/:group_id/members", GroupMembersController, :index
    resources "/groups/:group_id/join-requests", GroupJoinRequestsController, only: [:create, :update, :index]
  end

  scope "/", Thegm do
    pipe_through :api

    get "/isteapot", IsTeapotController, :index
    get "/deathcheck", DeathCheckController, :index
    post "/register", UsersController, :create
    post "/login", SessionsController, :create
    post "/confirmation/:id", ConfirmationCodesController, :create
  end
end
