defmodule Stone.Repo do
  use Ecto.Repo,
    otp_app: :stone,
    adapter: Ecto.Adapters.Postgres
end
