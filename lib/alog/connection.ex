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
