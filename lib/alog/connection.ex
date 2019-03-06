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
  def all(query) do
    iodata_query =  EAPC.all(query)

    # sub =
    #   from(m in __MODULE__,
    #     distinct: m.entry_id,
    #     order_by: [desc: :updated_at],
    #     select: m
    #   )
    #
    # query = from(m in subquery(sub), where: not m.deleted, select: m)


# SELECT
#   s0."id",
#   s0."name",
#   s0."entry_id",
#   s0."deleted",
#   s0."inserted_at",
#   s0."updated_at"
# FROM
#   (SELECT DISTINCT ON (d0."entry_id")
#       d0."id" AS "id"
#     , d0."name" AS "name"
#     , d0."entry_id" AS "entry_id"
#     , d0."deleted" AS "deleted"
#     , d0."inserted_at" AS "inserted_at"
#     , d0."updated_at" AS "updated_at"
#   FROM "drink_types" AS d0
#   ORDER BY d0."entry_id", d0."updated_at" DESC)
# AS s0 WHERE (NOT (s0."deleted"))


    query = iodata_query
    |> IO.iodata_to_binary()
    |> distinct_entry_id()

    IO.inspect query
    query
  end

  defp distinct_entry_id("SELECT " <> query) do
    IO.iodata_to_binary(["SELECT ", "DISTINCT ON (\"entry_id\" ) ", query])
  end

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
