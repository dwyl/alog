use Mix.Config

config :alog, Alog.Repo,
  username: "postgres",
  password: "docker",
  database: "routinedb",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/repo/test_app/"

config :alog, ecto_repos: [Alog.Repo]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :warn
