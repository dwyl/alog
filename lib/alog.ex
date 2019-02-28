defmodule Alog do
  use Ecto.Adapters.SQL,
    driver: :postgrex,
    migration_lock: "FOR UPDATE"

  @impl true
  def supports_ddl_transaction? do
    true
  end

  @behaviour Ecto.Adapter.Storage
  @behaviour Ecto.Adapter.Schema

  @impl true
  defdelegate storage_up(opts), to: Ecto.Adapters.Postgres

  @impl true
  defdelegate storage_down(opts), to: Ecto.Adapters.Postgres

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
end
