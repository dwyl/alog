defmodule AlogTest.AllTest do
  use Alog.TestApp.DataCase

  alias Alog.TestApp.{Comment}

  describe "all/0:" do
    test "succeeds" do
      {:ok, _comment} = %Comment{comment: "Hello Rob"}  |> Repo.insert()
      {:ok, _} = %Comment{comment: "Hello Dan"} |> Repo.insert()

      assert length(Repo.all(Comment)) == 2
    end
  end
end
