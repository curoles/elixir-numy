defmodule Numy.Vector do
  @moduledoc """
  Typical vector operations with `[float]` List.
  When list is long, we call NIF functions to speed up computation.

  Author: Igor Lesik 2019
  """

  @on_load :load_nifs

  @doc """
  Callback on module's load. Loads NIF shared library.
  """
  def load_nifs do
    mix_app = Mix.Project.config[:app]
    path = :filename.join(:code.priv_dir(mix_app), 'libnumy_vector')
    :erlang.load_nif(path, 0)
  end

  @doc """
  Convert list of numbers to list of floats (what we call vector).
  """
  @spec from_list([number]) :: [float]
  def from_list(list) do
    Numy.Enumy.all_to_float(list)
  end

  defguard is_two_vectors_equal_length(vector1, vector2) when
    is_list(vector1) and is_list(vector2) and length(vector1) == length(vector2)

  # Vector size when we use NIF implementation instead of pure Elixir code.
  @nif_watermark 100_000

  @doc """
  The dot product is the sum of the products of the corresponding entries
  of the two sequences (vectors) of numbers.
  """
  @spec dot_product([float], [float]) :: float
  def dot_product(vector1, vector2) when is_two_vectors_equal_length(vector1, vector2) do
    if length(vector1) < @nif_watermark do
      Numy.Enumy.dot_product(vector1, vector2)
    else
      nif_dot_product(vector1, vector2)
    end
  end

  @doc """
  NIF implementation of dot product.
  """
  def nif_dot_product(vector1, vector2) when is_two_vectors_equal_length(vector1, vector2) do
    raise "nif_dot_product/2 not implemented"
  end

end
