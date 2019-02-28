defmodule Alog.Connection do
  alias Ecto.Adapters.Postgres.Connection, as: EAPC

  @behaviour Ecto.Adapters.SQL.Connection
  @default_port 5432

  @impl true
  def child_spec(opts) do
    opts
    |> Keyword.put_new(:port, @default_port)
    |> Postgrex.child_spec()
  end

  @impl true
  defdelegate prepare_execute(conn, name, statement, params, opts), to: EAPC

  @impl true
  defdelegate execute(conn, query, params, opts), to: EAPC

  @impl true
  defdelegate query(conn, statement, params, opts), to: EAPC

  @impl true
  defdelegate stream(conn, statement, params, opts), to: EAPC

  @impl true
  defdelegate to_constraints(error_struct), to: EAPC

  @impl true
  defdelegate all(query), to: EAPC

  @impl true
  defdelegate update_all(query, prefix \\ nil), to: EAPC

  @impl true
  defdelegate delete_all(query), to: EAPC

  @impl true
  defdelegate insert(prefix, table, header, rows, on_conflict, returning), to: EAPC

  @impl true
  defdelegate update(prefix, table, fields, filters, returning), to: EAPC

  @impl true
  defdelegate delete(prefix, table, filters, returning), to: EAPC

  @impl true
  defdelegate execute_ddl(arg), to: EAPC

  @impl true
  defdelegate ddl_logs(result), to: EAPC
end
