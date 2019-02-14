defmodule Alog.Connection do
  @behaviour Ecto.Adapters.SQL.Connection

  @impl true
  defdelegate ddl_logs(result), to: Ecto.Adapter.Postgres

  @impl true
  defdelegate prepare_execute(connection, name, statement, params, options),
    to: Ecto.Adapter.Postgres

  @impl true
  defdelegate query(connection, statement, params, options), to: Ecto.Adapter.Postgres

  @impl true
  defdelegate stream(connection, statement, params, options), to: Ecto.Adapter.Postgres
end
