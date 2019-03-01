defmodule AlogTest.UpdateTest do
  # use Alog.TestApp.DataCase
  #
  # alias Alog.TestApp.{User, Helpers}
  #
  # describe "update/2:" do
  #   test "succeeds" do
  #     {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
  #
  #     assert {:ok, updated_user} = user |> User.changeset(%{postcode: "W2 3EC"}) |> User.update()
  #   end
  #
  #   test "updates" do
  #     {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
  #
  #     {:ok, updated_user} = user |> User.changeset(%{postcode: "W2 3EC"}) |> User.update()
  #
  #     assert updated_user.postcode == "W2 3EC"
  #   end
  #
  #   test "'get' returns most recently updated item" do
  #     {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
  #
  #     {:ok, updated_user} = user |> User.changeset(%{postcode: "W2 3EC"}) |> User.update()
  #
  #     assert User.get(user.entry_id) |> User.preload(:items) == updated_user
  #     assert User.get(user.entry_id).postcode == "W2 3EC"
  #   end
  #
  #   test "associations remain after update" do
  #     {:ok, user, _item} = Helpers.seed_data()
  #
  #     {:ok, _updated_user} = user |> User.changeset(%{postcode: "W2 3EC"}) |> User.update()
  #
  #     assert User.get(user.entry_id) |> User.preload(:items) |> Map.get(:items) |> length == 1
  #   end
  # end
end
