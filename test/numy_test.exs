defmodule NumyTest do
  use ExUnit.Case
  doctest Numy

  test "vector dot_product Elixir and NIF results match" do
    vec = Enum.to_list(1..1000) |> Enum.map(fn x -> x/2 end)
    erl_res = Numy.Vector.dot_product(vec, vec)
    nif_res = Numy.Vector.nif_dot_product(vec, vec)
    assert abs(erl_res - nif_res) < 0.00001
  end
end
