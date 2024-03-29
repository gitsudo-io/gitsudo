import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :github, GitHub.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "github_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :gitsudo, Gitsudo.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "gitsudo_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :gitsudo_web, GitsudoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "+t9+Fq3OZrwUC0BfJQ+UYi22IFguQ0TPyas6syuVbgWSpDetVvzl7LFV0mCf5wRk",
  server: false

# Print only warnings and errors during test
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :mfa]

# In test we don't send emails.
config :gitsudo, Gitsudo.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
