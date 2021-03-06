defmodule StoneWeb.Router do
  use StoneWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug Guardian.Plug.Pipeline, module: Stone.Guardian, error_handler: StoneWeb.AuthErrorHandler

    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource
  end

  scope "/api/v1", StoneWeb do
    pipe_through :api

    post "/sign_up", UserController, :create
    post "/sign_in", UserController, :sign_in
  end

  scope "/api/v1", StoneWeb do
    pipe_through [:api, :authenticated]

    # user
    get "/self", UserController, :show

    # transactions
    post "/withdrawal", TransactionController, :withdrawal
    post "/transfer", TransactionController, :transfer
    get "/transaction_id", TransactionController, :transaction_id

    # reports
    scope "/reports" do
      get "/day", ReportController, :day
      get "/month", ReportController, :month
      get "/year", ReportController, :year
      get "/total", ReportController, :total
    end
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: StoneWeb.Telemetry
    end
  end
end
