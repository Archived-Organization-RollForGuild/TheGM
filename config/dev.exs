use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# command from your terminal:
#
#     openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -keyout priv/server.key -out priv/server.pem
#
# The `http:` config below can be replaced with:
# https: [port: 4000, keyfile: "priv/server.key", certfile: "priv/server.pem"],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.
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
  region: "us-east-2",
  host: "s3.us-east-2.amazonaws.com",
  scheme: "https://"

config :thegm,
  api_url: "http://dev.api.rollforguild.com",
  web_url: "https://dev.rollforguild.com"
