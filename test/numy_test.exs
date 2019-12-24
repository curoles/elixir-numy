defmodule NumyTest do
  use ExUnit.Case
  doctest Numy

  test "greets the world" do
    assert Numy.hello() == :world
  end
end
