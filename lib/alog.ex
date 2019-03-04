defmodule Alog do
  use Ecto.Adapters.SQL,
    driver: :postgrex,
    migration_lock: "FOR UPDATE"

  alias Ecto.Adapters.Postgres, as: EAP

  @behaviour Ecto.Adapter.Storage

  @impl true
  def supports_ddl_transaction?, do: true

  @impl true
  defdelegate storage_up(opts), to: EAP

  @impl true
  defdelegate storage_down(opts), to: EAP

  # overrides insert/6 defined in Ecto.Adapters.SQL
  def insert(adapter_meta, %{source: "schema_migrations", prefix: prefix}, params, on_conflict, returning, opts) do
    insert_logic(adapter_meta, "schema_migrations", prefix, params, on_conflict, returning, opts)
  end

  def insert(adapter_meta, %{source: source, prefix: prefix}, params, on_conflict, returning, opts) do
    # converts params from a keyword list to a map
    params_map = Enum.into(params, %{})

    # removes inserted_at and updated_at from map (will not error if keys are not in map)
    map_for_cid = Map.drop(params_map, [:inserted_at, :updated_at])

    # creates a cid from the map witout the inserted_at and updated_at_values
    cid = Cid.cid(map_for_cid)

    # creates a unique entry_id for the data based on the CID generated
    entry_id = create_entry_id(source, adapter_meta, cid, 2)

    # updates params to ensure that timestamps, cid, and entry_id are all added.
    # then converts the map back into a list for use in existing functionality (original format)
    params =
      map_for_cid
      |> add_timestamps()
      |> Map.put(:cid, cid)
      |> Map.put(:entry_id, entry_id)
      |> Enum.into([])

    insert_logic(adapter_meta, source, prefix, params, on_conflict, returning, opts)
  end

  defp create_entry_id(source, adapter_meta, cid, n) do
    entry_id = String.slice(cid, 0..n)
    entry_id_query = "SELECT * FROM #{source} where entry_id='#{entry_id}'"
    {:ok, results} = Ecto.Adapters.SQL.query(adapter_meta, entry_id_query, [])

    if results.num_rows == 0 do
      entry_id
    else
      create_entry_id(source, adapter_meta, cid, n+1)
    end
  end

  defp add_timestamps(params) do
    params
    |> Enum.into(%{})
    |> Map.put_new(:inserted_at, NaiveDateTime.utc_now())
    |> Map.put_new(:updated_at, NaiveDateTime.utc_now())
  end

  defp insert_logic(adapter_meta, source, prefix, params, on_conflict, returning, opts) do
    {kind, conflict_params, _} = on_conflict
    {fields, values} = :lists.unzip(params)
    sql = Alog.Connection.insert(prefix, source, fields, [fields], on_conflict, returning)
    Ecto.Adapters.SQL.struct(adapter_meta, Alog.Connection, sql, :insert, source, [], values ++ conflict_params, kind, returning, opts)
  end
end
