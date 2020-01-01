defmodule NumyTest do
  use ExUnit.Case
  doctest Numy

  test "vector dot_product Elixir and NIF results match" do
    vec = Enum.to_list(1..1000) |> Enum.map(fn x -> x/2 end)
    erl_res = Numy.Vector.dot_product(vec, vec)
    nif_res = Numy.Vector.nif_dot_product(vec, vec)
    assert abs(erl_res - nif_res) < 0.00001
  end

  test "float sign, signbit,close?" do
    import Numy.Float
    assert sign(7.8748247) == 1 and sign(-7.656521) == -1 and sign(0.0) == 0
    assert signbit(0.0) == false and signbit(-0.0067424) == true and signbit(7471624.8741824) == false
    assert close?(-0.01, -0.01) == true and close?(-0.01, -0.02) == false and close?(-0.01, 0.01) == false
    assert close?(-0.01, -0.01000001, 0.000000001) == false and close?(-0.01, -0.01000001, 0.0001) == true
  end

  test "lapack LLS QR" do
    a = Numy.Lapack.new_tensor([3,5])
    Numy.Lapack.assign(a, [1,1,1,2,3,4,3,5,2,4,2,5,5,4,3])
    b = Numy.Lapack.new_tensor([2,5])
    Numy.Lapack.assign(b, [-10,-3,12,14,14,12,16,16,18,16])
    Numy.Lapack.solve_lls(a,b)
    #check [2,1],[1,1],[1,2] Numy.Lapack.data(b)
  end
end
