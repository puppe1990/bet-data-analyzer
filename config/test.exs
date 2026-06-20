import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :bet_data_analyzer, BetDataAnalyzer.Repo,
  database: Path.expand("../bet_data_analyzer_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bet_data_analyzer, BetDataAnalyzerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "62K16BqdaYuUTwWHlegdfOEK7kD43Gwrda5HmZ9H8OcUzQ/5+waGUZxE1tKilNxU",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

config :bet_data_analyzer, Oban,
  testing: :manual,
  engine: Oban.Engines.Lite,
  notifier: Oban.Notifiers.Isolated

config :bet_data_analyzer,
  sportmonks_http: BetDataAnalyzer.Sportmonks.Stub,
  sportmonks_api_token: "test-token",
  req_retry: false
