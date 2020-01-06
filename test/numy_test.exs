defmodule NumyTest do
  use ExUnit.Case
  doctest Numy

  test "float sign, signbit,close?" do
    import Numy.Float
    assert sign(7.8748247) == 1 and sign(-7.656521) == -1 and sign(0.0) == 0
    assert signbit(0.0) == false and signbit(-0.0067424) == true and signbit(7471624.8741824) == false
    assert close?(-0.01, -0.01) == true and close?(-0.01, -0.02) == false and close?(-0.01, 0.01) == false
    assert close?(-0.01, -0.01000001, 0.000000001) == false and close?(-0.01, -0.01000001, 0.0001) == true
  end

  test "vector add" do
    alias Numy.Vc, as: Vc
    alias Numy.Vcm, as: Vcm
    v = Numy.Vector.new([1,2,3])
    assert Vc.close?(Vc.add(v,v), Vc.scale(v,2))
    bv = Numy.BigVector.new([1,2,3])
    assert Vc.close?(Vc.add(v,v), Vc.scale(bv,2))
    lv = Numy.Lapack.Vector.new([1,2,3])
    Vcm.add!(lv,lv)
    assert Numy.Float.close?([2.0,4.0,6.0], Vc.data(lv))
    lv = Numy.Lapack.Vector.new([1,2,3])
    assert Numy.Float.close?([2.0,4.0,6.0], Vc.add(lv,lv) |> Vc.data)
  end

  test "vector ops" do
    alias Numy.Vc, as: Vc
    #alias Numy.Vcm, as: Vcm
    l = Enum.to_list(0..99_999)
    v = Numy.Vector.new(l)
    lv = Numy.Lapack.Vector.new(l)
    assert Vc.at(v, 12345) == Vc.at(lv, 12345)
    lv2 = Vc.add(lv,lv) |> Vc.sub(lv)
    #todo assert Vc.close?(lv, lv2)
  end

  test "lapack LLS QR" do
    a = Numy.Lapack.new_tensor([3,5])
    Numy.Lapack.assign(a, [1,1,1,2,3,4,3,5,2,4,2,5,5,4,3])
    b = Numy.Lapack.new_tensor([2,5])
    Numy.Lapack.assign(b, [-10,-3,12,14,14,12,16,16,18,16])
    Numy.Lapack.solve_lls(a,b)
    assert Numy.Float.close?(Numy.Lapack.data(b,6), [[2,1], [1,1], [1,2]])
    # Repeat one more time
    Numy.Tz.assign(a, [[1,1,1],[2,3,4],[3,5,2],[4,2,5],[5,4,3]])
    Numy.Tz.assign(b, [[-10,-3],[12,14],[14,12],[16,16],[18,16]])
    Numy.Lapack.solve_lls(a,b)
    solution = Numy.Lapack.data(b,2*3)
    assert Numy.Float.close?(solution, [[2,1], [1,1], [1,2]])
  end
end
