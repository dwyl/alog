defmodule AlogTest.UpdateTest do
  use Alog.TestApp.DataCase

  alias Alog.TestApp.{Comment, Helpers}

  test "adds new record" do
    {:ok, _} = Repo.insert(%Comment{} |> Comment.changeset(%{comment: "hi"}))

    [c | []] = Repo.all(Comment)

    {:ok, _} = Repo.update(Comment.changeset(c, %{comment: "hello"}))

    assert Repo.all(Comment) |> length == 2
  end
end
