defmodule AlogTest.DeleteTest do
  # use Alog.TestApp.DataCase
  #
  # alias Alog.TestApp.{User, Helpers}
  #
  # describe "delete/1:" do
  #   test "succeeds" do
  #     {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
  #     assert {:ok, _} = User.delete(user)
  #   end
  #
  #   test "deleted items are not retrieved with 'get'" do
  #     {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
  #     {:ok, _} = User.delete(user)
  #
  #     assert User.get(user.entry_id) == nil
  #   end
  #
  #   test "deleted items are not retrieved with 'all'" do
  #     {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
  #     {:ok, _} = User.delete(user)
  #
  #     assert length(User.all()) == 0
  #   end
  # end
  #
  # describe "delete/1 - with changeset:" do
  #   test "succeeds" do
  #     {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
  #     assert {:ok, _} = user |> User.changeset(%{}) |> User.delete()
  #   end
  #
  #   test "deleted items are not retrieved with 'get'" do
  #     {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
  #     {:ok, _} = user |> User.changeset(%{}) |> User.delete()
  #
  #     assert User.get(user.entry_id) == nil
  #   end
  #
  #   test "deleted items are not retrieved with 'all'" do
  #     {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
  #     {:ok, _} = user |> User.changeset(%{}) |> User.delete()
  #
  #     assert length(User.all()) == 0
  #   end
  # end
end
