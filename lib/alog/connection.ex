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
  def all(query) do
    iodata_query =  EAPC.all(query)

    query = iodata_query
    |> IO.iodata_to_binary()
    |> alogify_all_query()

    query
  end

  defp alogify_all_query(query) do
    query_data = get_query_data(query)
    # if all query is called during migration, some column used in the
    # alogify version might not be yet defined.
    # Return the "normal" query
    if (query_data["table_name"] == "\"schema_migrations\"") do
      query
    else
      subquery = IO.iodata_to_binary(
                  [ "SELECT DISTINCT ON (#{query_data["table_as"]}.\"entry_id\" ) ",
                    query_data["subquery_fields"],
                    get_deleted_field(query_data),
                    " FROM ",
                    query_data["table_name"], " AS ", query_data["table_as"],
                    query_data["rest_query"],
                    " ORDER BY #{query_data["table_as"]}.\"entry_id\", #{query_data["table_as"]}.\"inserted_at\" DESC"
                ]
              )

      IO.iodata_to_binary(
        ["SELECT ", query_data["field_names"], " FROM (", subquery, ") AS alogsubquery WHERE (NOT alogsubquery.\"deleted\")"]
      )
    end
  end

  defp get_query_data(query) do
    data = Regex.named_captures(~r/(\bSELECT\b)\s(?<fields>.*)\sFROM\s(?<table_name>.*)\sas\s(?<table_as>.*)(?<rest_query>.*)/i, query)
    data = Map.put(data, "field_names", Regex.replace(~r/#{data["table_as"]}/, data["fields"], "alogsubquery"))

    subquery_fields = data["fields"]
      |> String.split(",")
      |> Enum.map(fn f ->
        field_name = Regex.replace(~r/#{data["table_as"]}./, f, "")
        f <> " AS #{field_name}"
      end)
      |> Enum.join(", ")

    Map.put(data, "subquery_fields", subquery_fields)
  end

  defp get_deleted_field(query_data) do
    if String.contains?(query_data["subquery_fields"], "#{query_data["table_as"]}.\"deleted\"") do
      ""
    else
      ", #{query_data["table_as"]}.\"deleted\" AS \"deleted\""
    end
  end

  @impl true
  def execute_ddl({c, %Ecto.Migration.Table{} = table, columns})
      when c in [:create, :create_if_not_exists] do
    # TODO: need to determine if migration_source has been set in config
    # else name is :schema_migrations
    with name when name != :schema_migrations <- Map.get(table, :name),
         true <-
           Enum.any?(
             columns,
             fn
               {:add, field, _type, [primary_key: true]} when field != :cid -> true
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
