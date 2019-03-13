defmodule AlogTest.InsertTest do
  use Alog.TestApp.DataCase
  alias Alog.Repo
  alias Alog.TestApp.{Comment}

  describe "Repo.insert/2 - with Comment struct:" do
    test "succeeds" do
      Repo.insert(%Comment{comment: "hi"})
      num_comments = Comment |> Repo.all() |> length()
      assert num_comments == 1
    end

    test "inserting the same comment twice fails with changeset" do
      Repo.insert(%Comment{comment: "hi"})

      {atom, _changeset} =
        %Comment{}
        |> Comment.changeset(%{comment: "hi"})
        |> Repo.insert()

      assert atom == :error
    end

    # test "validates required fields" do
    #   {:error, changeset} =
    #     %User{}
    #     |> User.changeset(%{name: "Thor"})
    #     |> User.insert()
    #
    #   assert length(changeset.errors) > 0
    # end
    #
    # test "inserted user is available" do
    #   {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
    #
    #   assert User.get(user.entry_id) == user
    # end
  end

  #
  # describe "insert/1 - with struct:" do
  #   test "succeeds" do
  #     {:ok, user} = struct(User, Helpers.user_1_params()) |> User.insert()
  #
  #     assert User.get(user.entry_id) == user
  #   end
  #
  #   test "inserted user is available" do
  #     {:ok, user} = struct(User, Helpers.user_1_params()) |> User.insert()
  #
  #     assert User.get(user.entry_id) == user
  #   end
  # end
  #
  # describe "insert/1 - with nested changeset:" do
  #   test "succeeds" do
  #     assert {:ok, user} =
  #              %User{}
  #              |> User.user_and_item_changeset(
  #                Map.put(Helpers.user_1_params(), :items, [%{name: "Belt"}])
  #              )
  #              |> User.insert()
  #   end
  #
  #   test "item is associated with user" do
  #     {:ok, user} =
  #       %User{}
  #       |> User.user_and_item_changeset(
  #         Map.put(Helpers.user_1_params(), :items, [%{name: "Belt"}])
  #       )
  #       |> User.insert()
  #
  #     assert User.get(user.entry_id) |> Repo.preload(:items) |> Map.get(:items) |> length == 1
  #   end
  #
  #   test "associated item is inserted into database - has_many" do
  #     {:ok, _user} =
  #       %User{}
  #       |> User.user_and_item_changeset(
  #         Map.put(Helpers.user_1_params(), :items, [%{name: "Belt"}])
  #       )
  #       |> User.insert()
  #
  #     all_items = Item.all()
  #
  #     assert length(all_items) == 1
  #     assert List.first(all_items).entry_id
  #   end
  #
  #   test "associated item is inserted into database - belongs_to" do
  #     {:ok, _item} =
  #       %Item{}
  #       |> Item.changeset(Map.put(%{name: "Stormbreaker"}, :user, Helpers.user_1_params()))
  #       |> Item.insert()
  #
  #     all_users = User.all()
  #
  #     user = List.first(all_users)
  #
  #     assert length(all_users) == 1
  #     assert user.entry_id
  #     assert user.name == "Thor"
  #   end
  #
  #   test "two level deep nested associations" do
  #     {:ok, _user} =
  #       %User{}
  #       |> User.user_and_item_changeset(
  #         Map.put(Helpers.user_1_params(), :items, [
  #           %{name: "Stormbreaker", item_types: [%{type: "Axe"}]}
  #         ])
  #       )
  #       |> User.insert()
  #
  #     all_items = Item.all()
  #     all_types = ItemType.all()
  #
  #     item = List.first(all_items)
  #     type = List.first(all_types)
  #
  #     assert length(all_items) == 1
  #     assert length(all_types) == 1
  #
  #     assert item.entry_id
  #     assert item.name == "Stormbreaker"
  #
  #     assert type.entry_id
  #     assert type.type == "Axe"
  #   end
  # end
end
