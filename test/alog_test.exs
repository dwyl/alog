defmodule AlogTest do
  use TestApp.DataCase
  doctest Alog

  alias TestApp.User

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

      assert User.get(user.entry_id) == updated_user
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
end
