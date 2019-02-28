defmodule Alog.Connection do
  @behaviour Ecto.Adapters.SQL.Connection

  @impl true
  defdelegate child_spec(opts), to: Ecto.Adapters.Postgres.Connection

  @impl true
  defdelegate ddl_logs(result), to: Ecto.Adapters.Postgres.Connection

  @impl true
  defdelegate prepare_execute(connection, name, statement, params, options),
    to: Ecto.Adapters.Postgres.Connection

  @impl true
  defdelegate query(connection, statement, params, options), to: Ecto.Adapters.Postgres.Connection

  @impl true
  defdelegate stream(connection, statement, params, options),
    to: Ecto.Adapters.Postgres.Connection

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
        Ecto.Adapters.Postgres.Connection.execute_ddl({c, table, columns})

      _ ->
        Ecto.Adapters.Postgres.Connection.execute_ddl({c, table, update_columns(columns)})
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
      Ecto.Adapters.Postgres.Connection.execute_ddl(command)
    end
  end

  def execute_ddl({c, %Ecto.Migration.Index{unique: true}})
      when c in [:create, :create_if_not_exists] do
    raise ArgumentError, "you cannot create a unique index"
  end

  defdelegate execute_ddl(command), to: Ecto.Adapters.Postgres.Connection

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
  defdelegate all(a), to: Ecto.Adapters.Postgres.Connection

  @impl true
  defdelegate insert(a, b, c, d, e, f), to: Ecto.Adapters.Postgres.Connection

  @impl true
  defdelegate execute(a, b, c, d), to: Ecto.Adapters.Postgres.Connection

  @impl true
  defdelegate delete_all(a), to: Ecto.Adapters.Postgres.Connection

  @impl true
  defdelegate to_constraints(a), to: Ecto.Adapters.Postgres.Connection

  @impl true
  defdelegate update(a, b, c, d, e), to: Ecto.Adapters.Postgres.Connection
end
