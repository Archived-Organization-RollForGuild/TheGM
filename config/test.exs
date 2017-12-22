use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thegm, Thegm.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :thegm, Thegm.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "thegm_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :argon2_elixir,
  t_cost: 2,
  m_cost: 12
config :bcrypt_elixir, :log_rounds, 4
config :pbkdf2_elixir, :rounds, 1
