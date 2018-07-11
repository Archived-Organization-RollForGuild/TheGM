use Mix.Config

config :thegm, Thegm.Endpoint,
  http: [port: System.get_env("RFG_API_PORT")],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []


# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :thegm, Thegm.Repo,
  adapter: Ecto.Adapters.Postgres,
  hostname: System.get_env("RFG_API_DB_HOST"),
  username: System.get_env("RFG_API_DB_USER"),
  password: System.get_env("RFG_API_DB_PASS"),
  database: System.get_env("RFG_API_DB_NAME"),
  pool_size: 10,
  adapter: Ecto.Adapters.Postgres,
  types: Thegm.PostgresTypes

# In your config/config.exs file
config :thegm, Thegm.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("RFG_API_MAILGUN_KEY"),
  domain: "rollforguild.com"

config :mailchimp,
  api_key: System.get_env("RFG_API_MAILCHIMP_KEY")

config :google_maps,
  api_key: System.get_env("RFG_API_GOOGLE_API_KEY")

config :ex_aws, :s3,
  access_key_id: System.get_env("RFG_AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("RFG_AWS_SECRET_ACCESS_KEY"),
  region: System.get_env("RFG_API_AWS_REGION")

config :ex_aws,
  debug_requests: true

config :thegm,
  api_url: "http://dev.api.rollforguild.com",
  web_url: "https://dev.rollforguild.com"
