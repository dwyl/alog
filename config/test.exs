use Mix.Config

config :alog, Alog.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "test_app_dev",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/repo/test_app/"

config :alog, ecto_repos: [Alog.Repo]
