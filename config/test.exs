use Mix.Config

config :test_app, TestApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "test_app_dev",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/repo/test_app/"

config :test_app, ecto_repos: [TestApp.Repo]
