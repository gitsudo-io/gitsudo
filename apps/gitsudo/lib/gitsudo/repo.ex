defmodule Gitsudo.Repo do
  use Ecto.Repo,
    otp_app: :gitsudo,
    adapter: Ecto.Adapters.Postgres
end
