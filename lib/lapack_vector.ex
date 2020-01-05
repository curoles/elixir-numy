defmodule Numy.Lapack.Vector do
  @moduledoc """
  LAPACK Vector.

  Implements protocols: `Numy.Vc`, `Numy.Vcm`

  ## Example of mutating `add!`

      iex(7)> v = Numy.Lapack.Vector.new([1,2,3])
      %Numy.Lapack.Vector{lapack: #Numy.Lapack<shape: [...], ...>, nelm: 3}
      iex(8)> Numy.Vcm.add!(v,v)
      :ok
      iex(9)> Numy.Lapack.data(v.lapack)
      [2.0, 4.0, 6.0]

  ## Example of non-mutating `add`

      iex(3)> v = Numy.Lapack.Vector.new([1,2,3])
      %Numy.Lapack.Vector{lapack: #Numy.Lapack<shape: [...], ...>, nelm: 3}
      iex(4)> Numy.Vc.add(v,v)
      [1.0, 2.0, 3.0]
  """

  @enforce_keys [:nelm]
  defstruct [
    :nelm,   # length of the vector
    :lapack  # %Numy.Lapack structure
  ]

  def new(nelm) when is_integer(nelm) do
    %Numy.Lapack.Vector{nelm: nelm, lapack: Numy.Lapack.new_tensor([nelm])}
  end

  def new(list) when is_list(list) do
    nelm = length(list)
    v = %Numy.Lapack.Vector{nelm: nelm, lapack: Numy.Lapack.new_tensor([nelm])}
    cond do
      v.lapack == nil -> nil
      true ->
        Numy.Lapack.assign(v.lapack, Numy.Enumy.all_to_float(list))
        v
    end
  end

  defimpl Numy.Vc do

    def assign_zeros(v) when is_map(v) do
      Numy.Lapack.assign(v.lapack, List.duplicate(0.0, v.nelm))
      v
    end

    def assign_ones(v) when is_map(v) do
      Numy.Lapack.assign(v.lapack, List.duplicate(1.0, v.nelm))
      v
    end

    def assign_random(v) when is_map(v) do
      Numy.Lapack.assign(v.lapack, Numy.Float.make_list_randoms(v.nelm))
      v
    end

    def at(v, index, default \\ nil) when is_map(v) and is_integer(index) do
      #TODO Enum.at(v.data, index, default)
    end

    def empty?(v) when is_map(v) do
      v.nelm == 0
    end

    def close?(v1,v2) when is_map(v1) and is_map(v2) do
      Numy.Float.close?(v1.lapack.data, v2.lapack.data)
    end

    @doc """
    Add two vectors.

    ## Examples

        iex(5)> v = Numy.Lapack.Vector.new([1,2,3])
        %Numy.Vector{data: [1.0, 2.0, 3.0], nelm: 3}
        iex(6)> Numy.Vc.add(v, v)
        %Numy.Vector{data: [2.0, 4.0, 6.0], nelm: 3}
    """
    def add(v1, v2) when is_map(v1) and is_map(v2) do
      v3 = Numy.Lapack.Vector.new(min(v1.nelm, v2.nelm))
      Numy.Vcm.add!(v3, v2)
      Numy.Lapack.data(v3.lapack)
    end

    def sub(v1, v2) when is_map(v1) and is_map(v2) do
      res = Enum.zip(v1.data,v2.data) |> Enum.map(fn {a,b} -> a - b end)
      %Numy.Vector{nelm: min(v1.nelm,v2.nelm), data: res}
    end

    def multiply(v1, v2) when is_map(v1) and is_map(v2) do
      res = Enum.zip(v1.data,v2.data) |> Enum.map(fn {a,b} -> a * b end)
      %Numy.Vector{nelm: min(v1.nelm,v2.nelm), data: res}
    end

    def scale(v, factor) when is_map(v) and is_number(factor) do
      res = Enum.map(v.data, fn x -> x * factor end)
      %Numy.Vector{nelm: v.nelm, data: res}
    end

    def dot(v1, v2) when is_map(v1) and is_map(v2) do
      Numy.Enumy.dot_product(v1.data, v2.data)
    end

  end # defimpl Numy.Vc


  defimpl Numy.Vcm do

    @doc "dsafdfadsf"
    def add!(v1,v2) when is_map(v1) and is_map(v2) do
      try do
        Numy.Lapack.vector_add(v1.lapack.nif_resource, v2.lapack.nif_resource)
      rescue
        _ -> :error
      end
    end

  end # defimpl Numy.Vcm

end
