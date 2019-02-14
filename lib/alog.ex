defmodule Alog do
  use Ecto.Adapters.SQL,
    driver: :postgrex,
    migration_lock: "FOR UPDATE"

  @impl true
  def supports_ddl_transaction? do
    true
  end

  @behaviour Ecto.Adapter.Storage

  @impl true
  defdelegate storage_up(opts), to: Ecto.Adapters.Postgres

  @impl true
  defdelegate storage_down(opts), to: Ecto.Adapters.Postgres
end
