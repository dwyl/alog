defmodule Alog.TestApp.ItemType do
  use Ecto.Schema
  use Alog
  import Ecto.Changeset

  schema "item_types" do
    field(:type, :string)
    field(:entry_id, :string)
    field(:deleted, :boolean, default: false)

    many_to_many(
      :items,
      Alog.TestApp.Item,
      join_through: "items_item_types",
      join_keys: [item_type_id: :id, item_id: :id]
    )

    timestamps()
  end

  @doc false
  def changeset(address, attrs) do
    address
    |> cast(attrs, [:type])
    |> validate_required([:type])
  end
end
