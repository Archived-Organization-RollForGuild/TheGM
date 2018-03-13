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

    resources "/users", UsersController do
      resources "/avatar", UserAvatarsController, only: [:create, :delete], singleton: true
      resources "/password", UserPasswordsController, only: [:update], singleton: true
      resources "/email", UserEmailsController, only: [:update], singleton: true
    end


    resources "/groups", GroupsController, except: [:edit, :new] do
      resources "/members", GroupMembersController, only: [:index, :delete]
      resources "/join-requests", GroupJoinRequestsController, only: [:create, :update, :index]
    end


    resources "/threads", ThreadsController, only: [:create] do
      resources "/comments", ThreadCommentsController, only: [:create]
    end

    post "/logout", SessionsController, :delete
  end

  scope "/", Thegm do
    pipe_through :api

    get "/isteapot", IsTeapotController, :index
    get "/deathcheck", DeathCheckController, :index
    post "/register", UsersController, :create
    post "/login", SessionsController, :create
    get "/sessions/:id", SessionsController, :show
    post "/confirmation/:id", ConfirmationCodesController, :create
    get "/users/:id/avatar", UserAvatarsController, :show

    post "/resets", PasswordResetsController, :create
    put "/resets/:id", PasswordResetsController, :update
  end
end
