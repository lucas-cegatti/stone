# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :stone,
  ecto_repos: [Stone.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :stone, StoneWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "rly1zl9D39t6CeDLp00l4TATXsQWDyve7gq0ToVmgb+eifAQ1ebMIbD47qJy2OeI",
  render_errors: [view: StoneWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Stone.PubSub,
  live_view: [signing_salt: "Tw1NQQBZ"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Guardian Configuration
config :stone, Stone.Guardian,
  issuer: "stone",
  secret_key: "Wqw/rT0faU2jrib9S1y/GiXy3iBSTmZHwIkJR7sR3YsWGt3BwfR6UOfbI9Ollrq8"

config :money,
  default_currency: :BRL,
  separator: ".",
  delimiter: ","

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
