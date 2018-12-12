defmodule AlogTest.ConstraintTest do
  use Alog.TestApp.DataCase

  alias Alog.TestApp.{User, Helpers}

  describe "apply_constraints/1:" do
    test "returns error if not unique" do
      {:ok, user_1} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()

      assert {:error, user_2} =
               %User{}
               |> User.changeset(
                 Helpers.user_2_params()
                 |> Map.merge(%{username: user_1.username})
               )
               |> User.insert()

      assert user_2.errors == [username: {"has already been taken", []}]
    end
  end
end
