import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.

# Configures Elixir's Logger
level =
  case String.downcase(System.get_env("ELIXIR_LOG_LEVEL", "")) do
    "debug" -> :debug
    "info" -> :info
    "warn" -> :warn
    "error" -> :error
    0 -> :debug
    1 -> :info
    2 -> :warn
    3 -> :error
    _ -> :info
  end

config :logger, :console, level: level

# The block below contains prod specific runtime configuration.
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :github, GitHub.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :gitsudo, Gitsudo.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :gitsudo_web, GitsudoWeb.Endpoint,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  config :gitsudo_web, GitsudoWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :gitsudo_web, GitsudoWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :gitsudo_web, GitsudoWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :gitsudo, Gitsudo.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end

github_app_id =
  System.get_env("GITHUB_APP_ID") ||
    if config_env() != :test,
      do:
        raise("""
        environment variable GITHUB_APP_ID is missing!
        See https://docs.github.com/en/developers/apps/building-github-apps/authenticating-with-github-apps
        """)

# The GitHub app client id
github_client_id =
  System.get_env("GITHUB_CLIENT_ID") ||
    if config_env() != :test,
      do:
        raise("""
        environment variable GITHUB_CLIENT_ID is missing!
        See https://docs.github.com/en/rest/guides/basics-of-authentication
        """)

# The GitHub app client secret
github_client_secret =
  System.get_env("GITHUB_CLIENT_SECRET") ||
    if config_env() != :test,
      do:
        raise("""
        environment variable GITHUB_CLIENT_SECRET is missing!
        See https://docs.github.com/en/rest/guides/basics-of-authentication
        """)

# The salt to use to encrypt Plug session data
gitsudo_session_encryption_salt =
  System.get_env("GITSUDO_SESSION_ENCRYPTION_SALT") ||
    if config_env() != :test,
      do:
        raise("""
        environment variable GITSUDO_SESSION_ENCRYPTION_SALT is missing!
        See https://hexdocs.pm/plug/Plug.Session.COOKIE.html#module-options
        """)

config :github, GitHub,
  github_app_id: github_app_id,
  github_client_id: github_client_id,
  github_client_secret: github_client_secret

config :gitsudo_web, GitsudoWeb.Endpoint,
  github_app_id: github_app_id,
  github_client_id: github_client_id,
  github_client_secret: github_client_secret,
  gitsudo_session_encryption_salt: gitsudo_session_encryption_salt
