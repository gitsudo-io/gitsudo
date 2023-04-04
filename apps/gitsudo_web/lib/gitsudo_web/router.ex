defmodule GitsudoWeb.Router do
  use GitsudoWeb, :router

  import GitsudoWeb.UserAuth
  import GitsudoWeb.OrgScope

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {GitsudoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GitsudoWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/login", PageController, :login
  end

  pipeline :org do
    plug :fetch_org
  end

  scope "/", GitsudoWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/", PageController, :home
    get "/logout", PageController, :logout

    get "/:organization_name", OrganizationController, :show

    scope "/:organization_name" do
      pipe_through [:org]

      resources "/labels", LabelController, param: "name"
    end
  end

  scope "/", GitsudoWeb do
    pipe_through [:browser]

    get "/oauth/callback", OauthController, :callback
  end

  scope "/", GitsudoWeb do
    pipe_through :api

    post "/webhook", WebhookController, :webhook

    scope "/api" do
      resources "/org/", API.OrganizationController, name: "organization", param: "name", only: [] do
        pipe_through :org

        resources "/labels", API.LabelController
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", GitsudoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:gitsudo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GitsudoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
