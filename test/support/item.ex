defmodule Alog.TestApp.Item do
  use Ecto.Schema
  use Alog
  import Ecto.Changeset

  schema "items" do
    field(:name, :string)
    field(:entry_id, :string)
    field(:deleted, :boolean, default: false)

    belongs_to(:user, Alog.TestApp.User, foreign_key: :owner)

    many_to_many(
      :item_types,
      Alog.TestApp.ItemType,
      join_through: "items_item_types",
      join_keys: [item_id: :id, item_type_id: :id]
    )

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> cast_assoc(:item_types)
    |> cast_assoc(:user)
  end
end
