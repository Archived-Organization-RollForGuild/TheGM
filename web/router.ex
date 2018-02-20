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

    get "/users/:id", UsersController, :show
    put "/users/:id", UsersController, :update
    get "/users", UsersController, :index
    put "/users/:id/password", UserPasswordsController, :update
    put "/users/:id/email", UserEmailsController, :update
    resources "/users/:id/avatar", UserAvatarsController, only: [:create]

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
    get "/sessions/:id", SessionsController, :show
    post "/confirmation/:id", ConfirmationCodesController, :create


    post "/resets", PasswordResetsController, :create
    put "/resets/:id", PasswordResetsController, :update
  end
end
