defmodule AlogTest do
  use Alog.TestApp.DataCase
  doctest Alog

  alias Alog.TestApp.{User, Item, Helpers}

  describe "insert/1:" do
    test "succeeds" do
      assert {:ok, user} =
               User.insert(%{name: "Thor", username: "gdofthndr12", postcode: "E2 0SY"})
    end

    test "validates required fields" do
      {:error, changeset} = User.insert(%{name: "Thor"})

      assert length(changeset.errors) > 0
    end

    test "inserted user is available" do
      {:ok, user} = User.insert(%{name: "Thor", username: "gdofthndr12", postcode: "E2 0SY"})

      assert User.get(user.entry_id) == user
    end
  end

  describe "update/2:" do
    test "succeeds" do
      {:ok, user} = User.insert(%{name: "Thor", username: "gdofthndr12", postcode: "E2 0SY"})
      assert {:ok, updated_user} = User.update(user, %{postcode: "W2 3EC"})
    end

    test "'get' returns most recently updated item" do
      {:ok, user} = User.insert(%{name: "Thor", username: "gdofthndr12", postcode: "E2 0SY"})
      {:ok, updated_user} = User.update(user, %{postcode: "W2 3EC"})

      assert User.get(user.entry_id) |> User.preload(:items) == updated_user
    end
  end

  describe "get_history/1:" do
    test "gets all items" do
      {:ok, user} = User.insert(%{name: "Thor", username: "gdofthndr12", postcode: "E2 0SY"})
      {:ok, updated_user} = User.update(user, %{postcode: "W2 3EC"})

      assert length(User.get_history(updated_user)) == 2
    end
  end

  describe "all/0:" do
    test "succeeds" do
      {:ok, _} = User.insert(%{name: "Thor", username: "gdofthndr12", postcode: "E2 0SY"})
      {:ok, _} = User.insert(%{name: "Loki", username: "mschfmkr", postcode: "E1 6DR"})

      assert length(User.all()) == 2
    end

    test "does not include old items" do
      {:ok, user} = User.insert(%{name: "Thor", username: "gdofthndr12", postcode: "E2 0SY"})
      {:ok, _} = User.insert(%{name: "Loki", username: "mschfmkr", postcode: "E1 6DR"})
      {:ok, _} = User.update(user, %{postcode: "W2 3EC"})

      assert length(User.all()) == 2
    end
  end

  describe "delete/1:" do
    test "succeeds" do
      {:ok, user} = User.insert(%{name: "Thor", username: "gdofthndr12", postcode: "E2 0SY"})
      assert {:ok, _} = User.delete(user)
    end

    test "deleted items are not retrieved with 'get'" do
      {:ok, user} = User.insert(%{name: "Thor", username: "gdofthndr12", postcode: "E2 0SY"})
      {:ok, _} = User.delete(user)

      assert User.get(user.entry_id) == nil
    end

    test "deleted items are not retrieved with 'all'" do
      {:ok, user} = User.insert(%{name: "Thor", username: "gdofthndr12", postcode: "E2 0SY"})
      {:ok, _} = User.delete(user)

      assert length(User.all()) == 0
    end
  end

  describe "get_by/2:" do
    test "only returns one result" do
      {:ok, user} = User.insert(%{name: "Thor", username: "gdofthndr12", postcode: "E2 0SY"})
      {:ok, user_2} = User.insert(%{name: "Loki", username: "mschfmkr", postcode: "E2 0SY"})

      assert User.get_by(postcode: "E2 0SY") == user_2
    end

    test "works with multiple clauses" do
      {:ok, user} = User.insert(%{name: "Thor", username: "gdofthndr12", postcode: "E2 0SY"})
      {:ok, user_2} = User.insert(%{name: "Loki", username: "mschfmkr", postcode: "E2 0SY"})

      assert User.get_by(postcode: "E2 0SY", name: "Thor") == user
    end
  end

  describe "required fields" do
    test "schema without delete field raises error" do
      assert_raise RuntimeError, fn ->
        defmodule NoDeleteSchema do
          use Ecto.Schema
          use Alog

          schema "bad_schema" do
            field(:entry_id, :string)
            timestamps()
          end
        end
      end
    end

    test "schema without entry_id field raises error" do
      assert_raise RuntimeError, fn ->
        defmodule NoEntrySchema do
          use Ecto.Schema
          use Alog

          schema "bad_schema" do
            field(:deleted, :boolean, default: false)
            timestamps()
          end
        end
      end
    end

    test "schema with deleted field of wrong type raises error" do
      assert_raise RuntimeError, fn ->
        defmodule BadDeletedSchema do
          use Ecto.Schema
          use Alog

          schema "bad_schema" do
            field(:entry_id, :string)
            field(:deleted, :string)
            timestamps()
          end
        end
      end
    end

    test "both required fields do not raise error" do
      assert (fn ->
                defmodule GoodSchema do
                  use Ecto.Schema
                  use Alog

                  schema "bad_schema" do
                    field(:entry_id, :string)
                    field(:deleted, :boolean, default: false)
                    timestamps()
                  end
                end
              end).()
    end
  end

  describe "preload/2:" do
    test "preloads many_to_many associations" do
      {:ok, _, item} = Helpers.seed_data()

      # item types are not loaded by default
      assert_raise ArgumentError, fn ->
        item.entry_id
        |> Item.get()
        |> Map.get(:item_types)
        |> length()
      end

      assert item.entry_id
             |> Item.get()
             |> Item.preload(:item_types)
             |> Map.get(:item_types)
             |> length() == 1
    end

    test "preloads one_to_many associations" do
      {:ok, user, _} = Helpers.seed_data()

      # items are not loaded by default
      assert_raise ArgumentError, fn ->
        user.entry_id
        |> User.get()
        |> Map.get(:items)
        |> length()
      end

      assert user.entry_id
             |> User.get()
             |> User.preload(:items)
             |> Map.get(:items)
             |> length() == 1
    end

    test "preloads nested associations" do
      {:ok, user, item} = Helpers.seed_data()

      # item_types are not loaded by default
      assert_raise ArgumentError, fn ->
        item.entry_id
        |> Item.get()
        |> Map.get(:item_types)
        |> length()
      end

      assert user.entry_id
             |> User.get()
             |> User.preload(items: [:item_types])
             |> Map.get(:items)
             |> List.first()
             |> Map.get(:item_types)
             |> length() == 1
    end

    test "preloads two level deep nested associations" do
      {:ok, user, _} = Helpers.seed_data()

      assert user.entry_id
             |> User.get()
             |> User.preload(items: [item_types: [:items]])
             |> Map.get(:items)
             |> List.first()
             |> Map.get(:item_types)
             |> List.first()
             |> Map.get(:items)
             |> length() == 2
    end
  end
end
