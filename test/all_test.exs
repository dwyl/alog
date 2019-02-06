defmodule AlogTest.AllTest do
  use Alog.TestApp.DataCase

  alias Alog.TestApp.{User, Helpers}

  describe "all/0:" do
    test "succeeds" do
      {:ok, _} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
      {:ok, _} = %User{} |> User.changeset(Helpers.user_2_params()) |> User.insert()

      assert length(User.all()) == 2
    end

    test "does not include old items" do
      {:ok, user} = %User{} |> User.changeset(Helpers.user_1_params()) |> User.insert()
      {:ok, _} = %User{} |> User.changeset(Helpers.user_2_params()) |> User.insert()
      {:ok, _} = user |> User.changeset(%{postcode: "W2 3EC"}) |> User.update()

      assert length(User.all()) == 2
    end

    test "all return inserted_at original value" do
      {:ok, user} = %User{} |> User.changeset(Helpers.user_3_params()) |> User.insert()
      {:ok, user_updated} = user |> User.changeset(%{postcode: "W2 3EC"}) |> User.update()

      [user_all] = User.all()
      assert user_all.inserted_at == user.inserted_at
      assert user_all.postcode == user_updated.postcode
    end
  end
end
