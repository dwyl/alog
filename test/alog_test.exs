defmodule AlogTest do
  use ExUnit.Case
  doctest Alog

  test "greets the world" do
    assert Alog.hello() == :world
  end
end
