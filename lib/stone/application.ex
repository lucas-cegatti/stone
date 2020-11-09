defmodule Stone.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Stone.Repo,
      # Start the Telemetry supervisor
      StoneWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Stone.PubSub},
      # Start the Endpoint (http/https)
      StoneWeb.Endpoint,
      # Start a worker by calling: Stone.Worker.start_link(arg)
      # {Stone.Worker, arg}
      {Stone.Transactions.TransactionId, %{}},

      {Stone.Transactions.Ledgers, %{}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Stone.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    StoneWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
