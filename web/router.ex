defmodule Thegm.Router do
  use Thegm.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug Thegm.AuthenticateUser
  end

  pipeline :tryauth do
    plug Thegm.TryAuthenticateUser
  end

  scope "/", Thegm do
    pipe_through [:api, :auth]

    get "/rolldice", RollDiceController, :index

    resources "/users", UsersController do
      resources "/avatar", UserAvatarsController, only: [:create, :delete], singleton: true
      resources "/password", UserPasswordsController, only: [:update], singleton: true
    end


    resources "/groups", GroupsController, only: [:create, :update, :delete] do
      resources "/members", GroupMembersController, only: [:index, :delete]
      resources "/join-requests", GroupJoinRequestsController, only: [:create, :update, :index]
      resources "/threads", GroupThreadsController, only: [:create, :index, :show, :delete] do
        resources "/comments", GroupThreadCommentsController, only: [:create, :index]
      end
    end

    resources "/threads", ThreadsController, only: [:create, :delete] do
      resources "/comments", ThreadCommentsController, only: [:create, :delete]
    end

    post "/logout", SessionsController, :delete
  end

  scope "/", Thegm do
    pipe_through [:api, :tryauth]

    get "/isteapot", IsTeapotController, :index
    get "/deathcheck", DeathCheckController, :index
    post "/register", UsersController, :create
    post "/login", SessionsController, :create
    get "/sessions/:id", SessionsController, :show
    post "/confirmation/:id", ConfirmationCodesController, :create
    get "/users/:id/avatar", UserAvatarsController, :show
    get "/unique", UniqueController, :show

    post "/resets", PasswordResetsController, :create
    put "/resets/:id", PasswordResetsController, :update
    resources "/email", EmailChangeController, only: [:update]
    resources "/groups", GroupsController, only: [:show, :index]

    resources "/threads", ThreadsController, only: [:index, :show] do
      resources "/comments", ThreadCommentsController, only: [:index, :show]
    end
  end
end
