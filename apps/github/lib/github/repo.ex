defmodule GitHub.Repo do
  use Ecto.Repo,
    otp_app: :github,
    adapter: Ecto.Adapters.Postgres
end
