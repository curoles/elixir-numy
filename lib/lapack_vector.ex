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

  @doc "Create new Vector as a copy of other Vector"
  def new(%Numy.Lapack.Vector{nelm: sz, lapack: lpk} = _other_vec) do
    new_vec = Numy.Lapack.Vector.new(sz)
    Numy.Lapack.copy(new_vec.lapack, lpk)
    new_vec
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

    def data(v) when is_map(v) do
      Numy.Lapack.data(v.lapack)
    end

    def at(%Numy.Lapack.Vector{nelm: nelm}, index, default) when index < 0 or index >= nelm, do: default
    def at(v, index, _default) when is_map(v) and is_integer(index) do
      Numy.Lapack.vector_at(v.lapack.nif_resource, index)
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
      v = Numy.Lapack.Vector.new(v1) # make a copy
      Numy.Vcm.add!(v, v2)
      Numy.Lapack.data(v.lapack)
    end

    def sub(v1, v2) when is_map(v1) and is_map(v2) do
      res = Enum.zip(v1.data,v2.data) |> Enum.map(fn {a,b} -> a - b end)
      %Numy.Vector{nelm: min(v1.nelm,v2.nelm), data: res}
    end

    def mul(v1, v2) when is_map(v1) and is_map(v2) do
      res = Enum.zip(v1.data,v2.data) |> Enum.map(fn {a,b} -> a * b end)
      %Numy.Vector{nelm: min(v1.nelm,v2.nelm), data: res}
    end

    def div(v1, v2) when is_map(v1) and is_map(v2) do
      res = Enum.zip(v1.data,v2.data) |> Enum.map(fn {a,b} -> a / b end)
      %Numy.Vector{nelm: min(v1.nelm,v2.nelm), data: res}
    end

    def scale(v, factor) when is_map(v) and is_number(factor) do
      res = Enum.map(v.data, fn x -> x * factor end)
      %Numy.Vector{nelm: v.nelm, data: res}
    end

    def offset(v, off) when is_map(v) and is_number(off) do
      res = Enum.map(v.data, fn x -> x + off end)
      %Numy.Vector{nelm: v.nelm, data: res}
    end

    def dot(v1, v2) when is_map(v1) and is_map(v2) do
      Numy.Enumy.dot_product(v1.data, v2.data)
    end

    @doc "Sum of all elements, ∑aᵢ"
    def sum(v) do
      Enum.sum(v.data)
    end

    @doc "Average (∑aᵢ)/length"
    def average(%Numy.Vector{nelm: nelm, data: _}) when nelm == 0, do: 0.0
    def average(%Numy.Vector{nelm: nelm, data: _} = v) do
      Enum.sum(v.data) / nelm
    end

    @doc "Return max value"
    def max(v), do: Enum.max(v.data)

    @doc "Return min value"
    def min(v), do: Enum.min(v.data)

    @doc "Return index of max value"
    def max_index(v) when is_map(v) do
      max_val = Numy.Vc.max(v)
      Enum.find_index(v.data, fn x -> x == max_val end)
    end

    @doc "Return index of min value"
    def min_index(v) when is_map(v) do
      min_val = Numy.Vc.min(v)
      Enum.find_index(v.data, fn x -> x == min_val end)
    end

    @doc "Step function, aᵢ ← 0 if aᵢ < 0 else 1"
    def apply_heaviside(v, cutoff \\ 0.0) when is_map(v) do
      res = Enum.map(v.data, fn x -> if (x < cutoff), do: 0.0, else: 1.0 end)
      %{v | data: res}
    end

    @doc "f(x) = 1/(1 + e⁻ˣ)"
    def apply_sigmoid(v) when is_map(v) do
      sigmoid = fn x -> (1.0/(1.0 + :math.exp(-x))) end
      res = Enum.map(v.ata, fn x -> sigmoid.(x) end)
      %{v | data: res}
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
