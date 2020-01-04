#!/usr/bin/env elixir -S mix run

defmodule PerfBench do

  def test1() do
    l = Enum.to_list(1..100_000)
    v = Numy.Vector.new_from_list(l)
    bv = Numy.BigVector.new_from_list(l)

    alias Numy.Vc, as: Vc
    Benchee.run(
      %{"Vector" => fn -> Vc.add(v,v) end,
        "BigVector" => fn -> Vc.add(bv,bv) end
      },
      [ title: "vector add",
        print: %{
        benchmarking: false,
        fast_warning: false,
        configuration: false
      }]
    )
  end

  def test2() do
    alias Numy.Vc, as: Vc

    l = Enum.to_list(1..100_000)
    v = Numy.Vector.new_from_list(l)
    v2 = Vc.scale(v, 0.01)
    bv = Numy.BigVector.new_from_list(l)
    bv2 = Vc.scale(bv, 0.01)

    Benchee.run(
      %{"Vector" => fn -> Numy.Vector.mean_sq_err(v,v2) end,
        "BigVector" => fn -> Numy.BigVector.mean_sq_err(bv,bv2) end
      },
      [ title: "vector mean sq err",
        print: %{
        benchmarking: false,
        fast_warning: false,
        configuration: false
      }]
    )
  end

  def main(_args) do
    #test1()
    test2()
  end

end

PerfBench.main(System.argv)

