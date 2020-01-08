defmodule Numy.Enumy do
  @moduledoc """
  Extend Enum for homogeneous enumerables.
  """

  @doc """
  Check if all elements of a list are integers.

  ## Examples

      iex(1)> import Numy.Enumy
      Numy.Enumy
      iex(2)> all_integers?([1, 2, 3])
      true
      iex(3)> all_integers?([1.1, 2, 3])
      false
  """
  @spec all_integers?(Enumerable.t()) :: boolean
  def all_integers?(enumerable) do
    Enum.all?(enumerable, fn item -> is_integer(item) end)
  end

  @doc """
  Check if all elements of a list are floats.

  ## Examples

      iex(10)> import Numy.Enumy
      Numy.Enumy
      iex(11)> all_floats?([1.1, 2.2, 3.3])
      true
      iex(12)> all_floats?([1.1, 2.2, 3])
      false
  """
  @spec all_floats?(Enumerable.t()) :: boolean
  def all_floats?(enumerable) do
    Enum.all?(enumerable, fn item -> is_float(item) end)
  end

  @spec all_numbers?(Enumerable.t()) :: boolean
  def all_numbers?(enumerable) do
    Enum.all?(enumerable, fn item -> is_number(item) end)
  end

  @doc """
  Convert all numerical elements of a list to `float` type.

  ## Examples

      iex(13)> all_to_float([1.1, 2.2, 3])
      [1.1, 2.2, 3.0]
  """
  @spec all_to_float(Enumerable.t()) :: [float]
  def all_to_float(enumerable) do
    Enum.map(enumerable, fn item ->
      cond do
        is_float(item) ->
          item
        is_integer(item) ->
          item / 1  # idiomatic way to convert integer to float
        true ->
          raise "non numerical item"
      end
    end)
  end

  @doc """
  The dot product is the sum of the products of the corresponding entries
  of the two sequences of numbers.

  ## Examples

      iex> dot_product([1,2,3],[2,3,0])
      8
  """
  @spec dot_product([number], [number]) :: number
  def dot_product(vec1, _vec2) when vec1 == [], do: 0
  def dot_product(vec1,  vec2) when is_list(vec1) and is_list(vec2) do
    [h1|t1] = vec1
    [h2|t2] = vec2
    (h1*h2) + dot_product(t1, t2)
  end

  @doc """
  Get mean (average) of a sequence of numbers.

  ## Examples
      iex(14)> mean([1,2,3,4,5,6,7,8,9])
      5.0
  """
  @spec mean(Enumerable.t()) :: float
  def mean(enumerable) do
    Enum.sum(enumerable) / Enum.count(enumerable)
  end

  @doc "Sort elements with Quicksort"
  def sort([]), do: []
  def sort([pivot | tail]) do
    {left, right} = Enum.split_with(tail, fn(x) -> x < pivot end)
    sort(left) ++ [pivot] ++ sort(right)
  end

end
