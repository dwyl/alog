defmodule Alog do
  use Ecto.Adapters.SQL,
    driver: :postgrex,
    migration_lock: "FOR UPDATE"

  alias Ecto.Adapters.Postgres, as: EAP

  @behaviour Ecto.Adapter.Storage

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
end
