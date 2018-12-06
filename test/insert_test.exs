defmodule AlogTest.InsertTest do
  use Alog.TestApp.DataCase

  alias Alog.TestApp.{User, Helpers}

  describe "insert/1 - with changeset:" do
    test "succeeds" do
      assert {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
    end

    test "validates required fields" do
      {:error, changeset} =
        %User{}
        |> User.changeset(%{name: "Thor"})
        |> User.insert()

      assert length(changeset.errors) > 0
    end

    test "inserted user is available" do
      {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()

      assert User.get(user.entry_id) == user
    end
  end

  describe "insert/1 - with struct:" do
    test "succeeds" do
      {:ok, user} = struct(User, Helpers.user_1_params()) |> User.insert()

      assert User.get(user.entry_id) == user
    end

    test "inserted user is available" do
      {:ok, user} = struct(User, Helpers.user_1_params()) |> User.insert()

      assert User.get(user.entry_id) == user
    end
  end
end
