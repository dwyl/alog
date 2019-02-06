defmodule AlogTest.GetByTest do
  use Alog.TestApp.DataCase

  alias Alog.TestApp.{User, Helpers}

  describe "get_by/2:" do
    test "only returns one result" do
      {:ok, _user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()

      {:ok, user_2} =
        %User{}
        |> User.changeset(Map.put(Helpers.user_2_params(), :postcode, "E2 0SY"))
        |> User.insert()

      assert User.get_by(postcode: "E2 0SY") == user_2
    end

    test "works with multiple clauses" do
      {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
      {:ok, _user_2} = %User{} |> User.changeset(Helpers.user_2_params()) |> User.insert()

      assert User.get_by(postcode: "E2 0SY", name: "Thor") == user
    end

    test "works with map params " do
      {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()

      assert User.get_by(%{postcode: "E2 0SY", name: "Thor"}) == user
    end

    test "case_insensitive option" do
      {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()

      refute User.get_by(name: "thor") == user
      assert User.get_by([name: "thor"], case_insensitive: true) == user
      assert User.get_by(%{name: "thor"}, case_insensitive: true) == user
    end

    test "does not retrieve outdated results" do
      {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
      {:ok, _updated_user} = user |> User.changeset(%{postcode: "EC3 RST"}) |> User.update()

      assert User.get_by(postcode: "E2 0SY") == nil
    end

    test "does retrieve updated results if they match" do
      {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
      {:ok, updated_user} = user |> User.changeset(%{postcode: "EC3 RST"}) |> User.update()

      assert User.get_by(name: "Thor") |> User.preload(:items) == updated_user
    end

    test "ignores outdated and retrieves matching" do
      {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()

      {:ok, user_2} =
        %User{}
        |> User.changeset(Map.put(Helpers.user_2_params(), :postcode, "E2 0SY"))
        |> User.insert()

      {:ok, _} = user_2 |> User.changeset(%{postcode: "EC3 RST"}) |> User.update()

      assert User.get_by(postcode: "E2 0SY") == user
    end
  end
end
