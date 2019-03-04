defmodule AlogTest.PreloadTest do
  # use Alog.TestApp.DataCase
  #
  # alias Alog.TestApp.{User, Item, Helpers}
  #
  # test "preloads one_to_many associations" do
  #   {:ok, user, _} = Helpers.seed_data()
  #
  #   # items are not loaded by default
  #   assert_raise ArgumentError, fn ->
  #     user.entry_id
  #     |> User.get()
  #     |> Map.get(:items)
  #     |> length()
  #   end
  #
  #   assert user.entry_id
  #          |> User.get()
  #          |> User.preload(:items)
  #          |> Map.get(:items)
  #          |> length() == 1
  # end
  #
  # test "preloads nested associations" do
  #   {:ok, user, item} = Helpers.seed_data()
  #
  #   # item_types are not loaded by default
  #   assert_raise ArgumentError, fn ->
  #     item.entry_id
  #     |> Item.get()
  #     |> Map.get(:item_types)
  #     |> length()
  #   end
  #
  #   assert user.entry_id
  #          |> User.get()
  #          |> User.preload(items: [:item_types])
  #          |> Map.get(:items)
  #          |> List.first()
  #          |> Map.get(:item_types)
  #          |> length() == 1
  # end
  #
  # test "preloads two level deep nested associations" do
  #   {:ok, user, _} = Helpers.seed_data()
  #
  #   assert user.entry_id
  #          |> User.get()
  #          |> User.preload(items: [item_types: [:items]])
  #          |> Map.get(:items)
  #          |> List.first()
  #          |> Map.get(:item_types)
  #          |> List.first()
  #          |> Map.get(:items)
  #          |> length() == 2
  # end
end
