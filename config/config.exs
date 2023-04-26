# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configure Mix tasks and generators
config :github,
  namespace: GitHub,
  ecto_repos: [GitHub.Repo]

# Set Ecto Repo defaults
# Configure your database
config :github,
       GitHub.Repo,
       migration_timestamps: [type: :utc_datetime_usec]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :github, GitHub.Mailer, adapter: Swoosh.Adapters.Local

# Configure Mix tasks and generators
config :gitsudo,
  ecto_repos: [Gitsudo.Repo]

# Set Ecto Repo defaults
# Configure your database
config :gitsudo, Gitsudo.Repo, migration_timestamps: [type: :utc_datetime_usec]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :gitsudo, Gitsudo.Mailer, adapter: Swoosh.Adapters.Local

config :gitsudo_web,
  ecto_repos: [Gitsudo.Repo],
  generators: [context_app: :gitsudo]

# Configures the endpoint
config :gitsudo_web, GitsudoWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: GitsudoWeb.ErrorHTML, json: GitsudoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Gitsudo.PubSub,
  live_view: [signing_salt: "OpafNi1T"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.41",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/gitsudo_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/gitsudo_web/assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
