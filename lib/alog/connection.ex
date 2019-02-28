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
  defdelegate ddl_logs(result), to: EAPC

  @impl true
  defdelegate prepare_execute(connection, name, statement, params, options),
    to: EAPC

  @impl true
  defdelegate query(connection, statement, params, options), to: EAPC

  @impl true
  defdelegate stream(connection, statement, params, options),
    to: EAPC

  @impl true
  def execute_ddl({c, %Ecto.Migration.Table{} = table, columns} = command)
      when c in [:create, :create_if_not_exists] do
    # TODO: need to determine if migration_source has been set in config
    # else name is :schema_migrations
    with name when name != :schema_migrations <- Map.get(table, :name),
         true <-
           Enum.any?(
             columns,
             fn
               {:add, field, type, [primary_key: true]} -> true
               _ -> false
             end
           ) do
      raise ArgumentError, "you cannot add a primary key"
    else
      :schema_migrations ->
        EAPC.execute_ddl({c, table, columns})

      _ ->
        EAPC.execute_ddl({c, table, update_columns(columns)})
    end
  end

  def execute_ddl({:alter, %Ecto.Migration.Table{}, changes} = command) do
    with :ok <-
           Enum.each(
             changes,
             fn
               {:remove, :cid, _, _} ->
                 raise ArgumentError, "you cannot remove cid"

               {_, _, _, [primary_key: true]} ->
                 raise ArgumentError, "you cannot add a primary key"

               _ ->
                 nil
             end
           ) do
      EAPC.execute_ddl(command)
    end
  end

  def execute_ddl({c, %Ecto.Migration.Index{unique: true}})
      when c in [:create, :create_if_not_exists] do
    raise ArgumentError, "you cannot create a unique index"
  end

  defdelegate execute_ddl(command), to: EAPC

  # Add required columns if they are missing
  defp update_columns(columns) do
    [
      {:add, :cid, :binary, [primary_key: true]},
      {:add, :entry_id, :string, [null: false]},
      {:add, :deleted, :boolean, [default: false]},
      {:add, :inserted_at, :naive_datetime_usec, [null: false]},
      {:add, :updated_at, :naive_datetime_usec, [null: false]}
    ]
    |> Enum.reduce(columns, fn {_, c, _, _} = col, acc ->
      case Enum.find(acc, fn {_, a, _, _} -> a == c end) do
        nil -> acc ++ [col]
        _ -> acc
      end
    end)
  end

  # Temporary delegate functions to make tests work

  @impl true
  defdelegate all(query), to: EAPC

  @impl true
  defdelegate insert(prefix, table, header, rows, on_conflict, returning), to: EAPC

  @impl true
  defdelegate delete_all(query), to: EAPC

  @impl true
  defdelegate update(prefix, table, fields, filters, returning), to: EAPC

  @impl true
  defdelegate delete(prefix, table, filters, returning), to: EAPC

  @impl true
  defdelegate update_all(query, prefix \\ nil), to: EAPC
end
