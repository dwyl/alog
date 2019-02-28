defmodule Alog do
  use Ecto.Adapters.SQL,
    driver: :postgrex,
    migration_lock: "FOR UPDATE"

  alias Ecto.Adapters.Postgres, as: EAP

  @behaviour Ecto.Adapter.Storage
  @behaviour Ecto.Adapter.Schema

  # Why did we define our own version of this function?
  # Sorry if I have missed something that has been explained already.
  @impl true
  def supports_ddl_transaction?, do: true

  @impl true
  defdelegate storage_up(opts), to: EAP

  @impl true
  defdelegate storage_down(opts), to: EAP

  @impl true
  defdelegate structure_dump(default, config), to: EAP

  @impl true
  defdelegate structure_load(default, config), to: EAP

  @impl true
  def update(adapter_meta, %{source: source, prefix: prefix}, fields, params, returning, opts) do
    cid = Keyword.get(params, :cid)
    query = "SELECT * FROM #{source} where cid='#{cid}'"
    {:ok, old} = Ecto.Adapters.SQL.query(adapter_meta, query, [])

    new_params =
      Enum.with_index(old.columns)
      |> Enum.map(fn {c, i} ->
        case Keyword.get(fields, String.to_existing_atom(c)) do
          _ when c == "cid" ->
            nil

          nil ->
            {String.to_existing_atom(c), old.rows |> List.first() |> Enum.at(i)}

          new ->
            {String.to_existing_atom(c), new}
        end
      end)
      |> Enum.filter(&(not is_nil(&1)))
      |> Keyword.new()

    insert(
      adapter_meta,
      %{source: source, prefix: prefix},
      new_params,
      {:raise, [], []},
      returning,
      opts
    )
  end

  @impl true
  def autogenerate(:binary_id), do: nil

  @impl true
  def loaders(:binary_id, type), do: [:binary, type]
  def loaders(_primitive, type), do: [type]

  @impl true
  def dumpers(:binary_id, type), do: [:binary, type]
  def dumpers(_primitive, type), do: [type]

  # overrides insert/6 defined in Ecto.Adapters.SQL
  @impl true
  def insert(
        adapter_meta,
        %{source: source, prefix: prefix},
        params,
        on_conflict,
        returning,
        opts
      ) do
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
      # <==== Should this be Map.put(:id, cid)??????????
      |> Map.put(:cid, cid)
      |> Map.put(:entry_id, entry_id)
      |> Enum.into([])

    {kind, conflict_params, _} = on_conflict
    {fields, values} = :lists.unzip(params)
    sql = @conn.insert(prefix, source, fields, [fields], on_conflict, returning)

    Ecto.Adapters.SQL.struct(
      adapter_meta,
      @conn,
      sql,
      :insert,
      source,
      [],
      values ++ conflict_params,
      kind,
      returning,
      opts
    )
  end

  # I think that this step need to also make sure that the data is not an exact copy.
  # if the full cid already exists then this is duplicate data.
  # Should we insert duplicate data.
  # i was thinking maybe if it was existing data but not the most recent data we should re-insert the data
  # e.g. if the comment was hi, edited to hey, and then changed back to hi.
  defp create_entry_id(source, adapter_meta, cid, n) do
    entry_id = String.slice(cid, 0..n)
    entry_id_query = "SELECT * FROM #{source} where entry_id='#{entry_id}'"
    {:ok, results} = Ecto.Adapters.SQL.query(adapter_meta, entry_id_query, [])

    if results.num_rows == 0 do
      entry_id
    else
      create_entry_id(source, adapter_meta, cid, n + 1)
    end
  end

  defp add_timestamps(params) do
    params
    |> Enum.into(%{})
    |> Map.put_new(:inserted_at, NaiveDateTime.utc_now())
    |> Map.put_new(:updated_at, NaiveDateTime.utc_now())
  end
end
