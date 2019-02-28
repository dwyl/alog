defmodule AlogTest.UpdateTest do
  use Alog.TestApp.DataCase

  alias Alog.TestApp.{User, Helpers}

  test "adds new record" do
    {:ok, u} = Repo.insert(%User{name: "hi", username: "hi", postcode: "hi"})

    {:ok, _} = Repo.update(User.changeset(u, %{name: "hello"}))

    assert Repo.all(User) |> length == 2
  end

  test "return value of update is correct" do
    {:ok, user} = Repo.insert(%User{name: "hi", username: "hi", postcode: "hi"})

    {:ok, updated_user} = Repo.update(User.changeset(user, %{name: "hello"}))

    assert user.cid !== updated_user.cid
  end
end
