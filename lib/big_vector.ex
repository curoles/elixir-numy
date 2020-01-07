defmodule Numy.BigVector do
  @moduledoc """
  BigVector, uses Flow, experimental, does not show good results yet.

  Implements protocols: `Numy.Vc`
  """

  @enforce_keys [:nelm]
  defstruct [
    :nelm, # length of the vector
    :data  # actual data, type is list
  ]

  def new(nelm) when is_integer(nelm) do
    %Numy.BigVector{nelm: nelm, data: List.duplicate(0.0, nelm)}
  end

  def new(list) when is_list(list) do
    %Numy.BigVector{nelm: length(list), data: Numy.Enumy.all_to_float(list)}
  end

  @doc "Create new Vector as a copy of other Vector"
  def new(%Numy.BigVector{nelm: sz, data: d} = _v) do
    %Numy.BigVector{nelm: sz, data: d}
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

    def data(v) when is_map(v) do
      v.data
    end

    def at(v, index, default \\ nil) when is_map(v) and is_integer(index) do
      Enum.at(v.data, index, default)
    end

    def empty?(v) when is_map(v) do
      v.nelm == 0
    end

    def equal?(v1,v2) when is_map(v1) and is_map(v2) do
      Numy.Float.equal?(v1.data, v2.data)
    end

    @doc """
    Add two vectors.

    ## Examples

        iex(5)> v = Numy.BigVector.new([1,2,3])
        %Numy.BigVector{data: [1.0, 2.0, 3.0], nelm: 3}
        iex(6)> Numy.Vc.add(v, v)
        %Numy.BigVector{data: [2.0, 4.0, 6.0], nelm: 3}
    """
    def add(v1, v2) when is_map(v1) and is_map(v2) do
      res = Enum.zip(v1.data,v2.data)
        |> Flow.from_enumerable
        |> Flow.map(fn {a,b} -> a + b end)
        |> Enum.to_list
      %Numy.BigVector{nelm: min(v1.nelm,v2.nelm), data: res}
    end

    def sub(v1, v2) when is_map(v1) and is_map(v2) do
      res = Enum.zip(v1.data,v2.data)
        |> Flow.from_enumerable
        |> Flow.map(fn {a,b} -> a - b end)
        |> Enum.to_list
      %Numy.BigVector{nelm: min(v1.nelm,v2.nelm), data: res}
    end

    def mul(v1, v2) when is_map(v1) and is_map(v2) do
      res = Enum.zip(v1.data,v2.data)
        |> Flow.from_enumerable
        |> Flow.map(fn {a,b} -> a * b end)
        |> Enum.to_list
      %Numy.BigVector{nelm: min(v1.nelm,v2.nelm), data: res}
    end

    def div(v1, v2) when is_map(v1) and is_map(v2) do
      res = Enum.zip(v1.data,v2.data)
        |> Flow.from_enumerable
        |> Flow.map(fn {a,b} -> a / b end)
        |> Enum.to_list
      %Numy.BigVector{nelm: min(v1.nelm,v2.nelm), data: res}
    end

    def scale(v, factor) when is_map(v) and is_number(factor) do
      res = Enum.map(v.data, fn x -> x * factor end)
      %Numy.BigVector{nelm: v.nelm, data: res}
    end

    def offset(v, off) when is_map(v) and is_number(off) do
      res = Enum.map(v.data, fn x -> x + off end)
      %Numy.BigVector{nelm: v.nelm, data: res}
    end

    def dot(v1, v2) when is_map(v1) and is_map(v2) do
      Numy.Enumy.dot_product(v1.data, v2.data)
    end

    @doc "Sum of all elements, ∑aᵢ"
    def sum(v) when is_map(v) do
      Enum.sum(v.data)
    end

    @doc "Average (∑aᵢ)/length"
    def average(%Numy.BigVector{nelm: nelm, data: _}) when nelm == 0, do: 0.0
    def average(%Numy.BigVector{nelm: nelm, data: _} = v) do
      Numy.Vc.sum(v) / nelm
    end

    @doc "Return max value"
    def max(v) when is_map(v), do: Enum.max(v.data)

    @doc "Return min value"
    def min(v) when is_map(v), do: Enum.min(v.data)

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

  end # defimpl Numy.Vc do

  def mean_sq_err(v1, v2) do
    sum_sq_err = Enum.zip(v1.data, v2.data)
    |> Flow.from_enumerable
    |> Flow.map(fn {a,b} -> (a - b)*(a - b) end)
    |> Enum.sum

    sum_sq_err / min(v1.nelm, v2.nelm)
  end

  def root_mean_sq_err(v1, v2) do
    :math.sqrt(mean_sq_err(v1,v2))
  end
end
