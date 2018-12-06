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
  end
end
