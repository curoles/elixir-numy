defmodule Numy.Vector do
  @moduledoc """
  Vector, basic implementation.

  Implements protocols: `Numy.Vc`
  """

  @enforce_keys [:nelm]
  defstruct [
    :nelm, # length of the vector
    :data  # actual data, type is list
  ]

  def new(nelm) when is_integer(nelm) do
    %Numy.Vector{nelm: nelm, data: List.duplicate(0.0, nelm)}
  end

  def new(list) when is_list(list) do
    %Numy.Vector{nelm: length(list), data: Numy.Enumy.all_to_float(list)}
  end

  @doc "Create new Vector as a copy of other Vector"
  def new(%Numy.Vector{nelm: sz, data: d} = _v) do
    %Numy.Vector{nelm: sz, data: d}
  end

  @doc "Create new Vector as a concatenation of 2"
  def new(%Numy.Vector{nelm: sz1, data: d1} = _v1,
          %Numy.Vector{nelm: sz2, data: d2} = _v2) do
    %Numy.Vector{nelm: sz1+sz2, data: d1 ++ d2}
  end

  defimpl Numy.Vc do

    def assign_zeros(v) when is_map(v) do
      %{v | data: List.duplicate(0.0, v.nelm)}
    end

    def assign_ones(v) when is_map(v) do
      %{v | data: List.duplicate(1.0, v.nelm)}
    end

    def assign_random(v) when is_map(v) do
      %{v | data: Numy.Float.make_list_randoms(v.nelm)}
    end

    def assign_all(v, val) when is_map(v) and is_number(val) do
      %{v | data: List.duplicate(val, v.nelm)}
    end

    def data(v, nelm) when is_map(v) and is_integer(nelm) do
      if nelm < 0 do
        v.data
      else
        Enum.take(v.data, nelm)
      end
    end

    def at(v, index, default \\ nil) when is_map(v) and is_integer(index) do
      Enum.at(v.data, index, default)
    end

    def empty?(v) when is_map(v) do
      v.nelm == 0
    end

    def size(v) when is_map(v) do
      v.nelm
    end

    def equal?(v1,v2) when is_map(v1) and is_map(v2) do
      Numy.Float.equal?(v1.data, v2.data)
    end

    @doc """
    Add two vectors.

    ## Examples

        iex(5)> v = Numy.Vector.new([1,2,3])
        %Numy.Vector{data: [1.0, 2.0, 3.0], nelm: 3}
        iex(6)> Numy.Vc.add(v, v)
        %Numy.Vector{data: [2.0, 4.0, 6.0], nelm: 3}
    """
    def add(v1, v2) when is_map(v1) and is_map(v2) do
      res = Enum.zip(v1.data,v2.data) |> Enum.map(fn {a,b} -> a + b end)
      %Numy.Vector{nelm: min(v1.nelm,v2.nelm), data: res}
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

    def offset(%Numy.Vector{nelm: nelm, data: data}, off) when is_number(off) do
      %Numy.Vector{nelm: nelm, data: Enum.map(data, fn x -> x + off end)}
    end

    def negate(%Numy.Vector{nelm: nelm, data: data}) do
      %Numy.Vector{nelm: nelm, data: Enum.map(data, fn x -> -x end)}
    end

    def dot(v1, v2) when is_map(v1) and is_map(v2) do
      Numy.Enumy.dot_product(v1.data, v2.data)
    end

    @doc "Sum of all elements, ∑aᵢ"
    def sum(v) do
      Enum.sum(v.data)
    end

    @doc "Average (∑aᵢ)/length"
    def mean(%Numy.Vector{nelm: nelm, data: _}) when nelm == 0, do: 0.0
    def mean(%Numy.Vector{nelm: nelm, data: _} = v) do
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
      res = Enum.map(v.data, fn x -> sigmoid.(x) end)
      %{v | data: res}
    end

    def sort(v) when is_map(v) do
      Numy.Vector.new(Enum.sort(v.data))
    end

    def reverse(v) when is_map(v) do
      Numy.Vector.new(Enum.reverse(v.data))
    end

    @doc "Create new Vector as a concatenation of 2"
    def concat(%Numy.Vector{nelm: sz1, data: d1} = _v1,
               %Numy.Vector{nelm: sz2, data: d2} = _v2) do
      %Numy.Vector{nelm: sz1+sz2, data: d1 ++ d2}
    end

    def find(v,val) when is_map(v) and is_number(val) do
      Enum.find_index(v.data, fn x -> x == (val / 1) end)
    end

    def contains?(v,val) when is_map(v) and is_number(val) do
      Enum.member?(v.data, (val / 1))
    end

  end # defimpl Numy.Vc do

  def mean_sq_err(v1, v2) do
    sum_sq_err = Enum.zip(v1.data, v2.data)
    |> Enum.map(fn {a,b} -> (a - b)*(a - b) end)
    |> Enum.sum

    sum_sq_err / min(v1.nelm, v2.nelm)
  end

  def root_mean_sq_err(v1, v2) do
    :math.sqrt(mean_sq_err(v1,v2))
  end
end
