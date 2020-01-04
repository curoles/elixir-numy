defmodule Numy.Vector do
  @moduledoc """
  Vector, basic implementation.
  """

  @enforce_keys [:nelm]
  defstruct [
    :nelm, # length of the vector
    :data  # actual data, type is list
  ]

  def new(nelm) when is_integer(nelm) do
    %Numy.Vector{nelm: nelm, data: List.duplicate(0.0, nelm)}
  end

  def new_from_list(list) do
    %Numy.Vector{nelm: length(list), data: Numy.Enumy.all_to_float(list)}
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

    def at(v, index, default \\ nil) when is_map(v) and is_integer(index) do
      Enum.at(v.data, index, default)
    end

    def empty?(v) when is_map(v) do
      v.nelm == 0
    end

    def close?(v1,v2) when is_map(v1) and is_map(v2) do
      Numy.Float.close?(v1.data, v2.data)
    end

    @doc """
    Add two vectors.

    ## Examples

        iex(5)> v = Numy.Vector.new_from_list([1,2,3])
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
