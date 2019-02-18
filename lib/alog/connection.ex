defmodule Alog.Connection do
  @behaviour Ecto.Adapters.SQL.Connection

  @impl true
  defdelegate child_spec(opts), to: Ecto.Adapters.Postgres.Connection

  @impl true
  defdelegate ddl_logs(result), to: Ecto.Adapter.Postgres.Connection

  @impl true
  defdelegate prepare_execute(connection, name, statement, params, options),
    to: Ecto.Adapter.Postgres.Connection

  @impl true
  defdelegate query(connection, statement, params, options), to: Ecto.Adapter.Postgres.Connection

  @impl true
  defdelegate stream(connection, statement, params, options), to: Ecto.Adapter.Postgres.Connection

  @impl true
  def execute_ddl({c, %Ecto.Migration.Table{} = table, columns} = command)
      when c in [:create, :create_if_not_exists] do
    case Enum.any?(
           columns,
           fn
             {:add, field, type, [primary_key: true]} -> true
             _ -> false
           end
         ) do
      true ->
        raise ArgumentError, "you cannot add a primary key"

      false ->
        Ecto.Adapter.Postgres.Connection.execute_ddl(
          {c, table, subcommand ++ [{:add, :cid, "varchar", [primary_key: true]}]}
        )
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
      Ecto.Adapter.Postgres.Connection.execute_ddl(command)
    end
  end

  def execute_ddl({:create, %Ecto.Migration.Index{}} = command) do
  end

  def execute_ddl({:create_if_not_exists, %Ecto.Migration.Index{}} = command) do
  end

  defdelegate execute_ddl(command), to: Ecto.Adapter.Postgres.Connection
end
