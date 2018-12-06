defmodule Alog.TestApp.Helpers do
  alias Alog.TestApp.{User, Item, ItemType}
  alias Alog.Repo

  def seed_data() do
    {:ok, item_type} = %ItemType{} |> ItemType.changeset(%{type: "Weapon"}) |> ItemType.insert()

    {:ok, item} = %Item{} |> Item.changeset(%{name: "Mjolnir"}) |> Item.insert()
    {:ok, item_2} = %Item{} |> Item.changeset(%{name: "Staff"}) |> Item.insert()

    {:ok, item} = add_type_to_item(item, item_type)
    {:ok, _item_2} = add_type_to_item(item_2, item_type)

    {:ok, user} =
      %User{}
      |> User.changeset(%{name: "Thor", username: "gdofthndr12", postcode: "E2 0SY"})
      |> User.insert()

    {:ok, user} = add_item_to_user(user, item)

    {:ok, user, item}
  end

  def add_type_to_item(item, type) do
    item
    |> Item.preload([:item_types, :user])
    |> Map.put(:id, nil)
    |> Map.put(:inserted_at, nil)
    |> Map.put(:updated_at, nil)
    |> Item.changeset(%{})
    |> Ecto.Changeset.put_assoc(:item_types, [type])
    |> Repo.insert()
  end

  def add_item_to_user(user, item) do
    user
    |> User.preload([:items])
    |> Map.put(:id, nil)
    |> Map.put(:inserted_at, nil)
    |> Map.put(:updated_at, nil)
    |> User.changeset(%{})
    |> Ecto.Changeset.put_assoc(:items, [item])
    |> Repo.insert()
  end
end
