defmodule Numy.Enumy do
  @moduledoc """
  Extend Enum for homogeneous enumerables.
  """

  @spec all_integers?(Enumerable.t()) :: boolean
  def all_integers?(enumerable) do
    Enum.all?(enumerable, fn item -> is_integer(item) end)
  end

  @spec all_floats?(Enumerable.t()) :: boolean
  def all_floats?(enumerable) do
    Enum.all?(enumerable, fn item -> is_float(item) end)
  end

  @spec all_numbers?(Enumerable.t()) :: boolean
  def all_numbers?(enumerable) do
    Enum.all?(enumerable, fn item -> is_number(item) end)
  end

  @spec all_to_float(Enumerable.t()) :: [float]
  def all_to_float(enumerable) do
    Enum.map(enumerable, fn item ->
      cond do
        is_float(item) ->
          item
        is_integer(item) ->
          item / 1
        true ->
          raise "non numerical item"
      end
    end)
  end

  @spec dot_product([number], [number]) :: number
  def dot_product(r1, _r2) when r1 == [], do: 0
  def dot_product(r1, r2) when is_list(r1) and is_list(r2) do
    [h1|t1] = r1
    [h2|t2] = r2
    (h1*h2) + dot_product(t1, t2)
  end

  @spec mean(Enumerable.t()) :: float
  def mean(enumerable) do
    Enum.sum(enumerable) / Enum.count(enumerable)
  end
end
