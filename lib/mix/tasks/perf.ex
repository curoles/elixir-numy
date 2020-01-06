defmodule Mix.Tasks.Perf do
  use Mix.Task

  @moduledoc """
  mix perf
  """

  def run(_) do
    _cfg = Benchee.init(%{
      print: %{
        benchmarking: false,
        fast_warning: false,
        configuration: false
      }
    })
    test_vector_add(100_000)
    #test2()
  end

  def test_vector_add(n) do
    l = Enum.to_list(1..n)
    v = Numy.Vector.new(l)
    bv = Numy.BigVector.new(l)
    lv = Numy.Lapack.Vector.new(l)

    alias Numy.Vc, as: Vc
    alias Numy.Vcm, as: Vcm
    Benchee.run(
      %{"Vector" => fn -> Vc.add(v,v) end,
        "BigVector" => fn -> Vc.add(bv,bv) end,
        "Lapack non-mutating" => fn -> Vc.add(lv,lv) end,
        "Lapack mutating" => fn -> Vcm.add!(lv,lv) end,
      },
      [ title: "Add vectors size #{n}",
        print: %{benchmarking: false, fast_warning: false, configuration: false}
      ]
    )
  end

  def test2() do
    alias Numy.Vc, as: Vc

    l = Enum.to_list(1..100_000)
    v = Numy.Vector.new(l)
    v2 = Vc.scale(v, 0.01)
    bv = Numy.BigVector.new(l)
    bv2 = Vc.scale(bv, 0.01)

    Benchee.run(
      %{"Vector" => fn -> Numy.Vector.mean_sq_err(v,v2) end,
        "BigVector" => fn -> Numy.BigVector.mean_sq_err(bv,bv2) end
      },
      [ title: "vector mean sq err",
        print: %{benchmarking: false, fast_warning: false, configuration: false}
      ]
    )
  end

end

