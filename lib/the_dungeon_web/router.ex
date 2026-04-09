defmodule TheDungeonWeb.Router do
  use TheDungeonWeb, :router

  import TheDungeonWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TheDungeonWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :require_admin do
    plug TheDungeonWeb.Plugs.AdminAuth
  end

  scope "/", TheDungeonWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:the_dungeon, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TheDungeonWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # Admin login (public)
  scope "/admin", TheDungeonWeb do
    pipe_through [:browser]

    get "/login", AdminSessionController, :new
    post "/login", AdminSessionController, :create
    delete "/logout", AdminSessionController, :delete
  end

  # Admin dashboard (admin-authed)
  scope "/admin", TheDungeonWeb do
    pipe_through [:browser, :require_admin]

    live_session :admin do
      live "/", Admin.DashboardLive, :index
      live "/users", Admin.UsersLive, :index
    end
  end

  ## Authentication routes

  scope "/", TheDungeonWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live "/users/register", UserRegistrationLive, :new
  end

  scope "/", TheDungeonWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: [{TheDungeonWeb.UserAuth, :ensure_authenticated}] do
      live "/book", BookingLive, :index
      live "/profile", ProfileLive, :show
    end
  end

  scope "/", TheDungeonWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
