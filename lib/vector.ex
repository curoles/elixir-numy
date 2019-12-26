defmodule Numy.Vector do
  @moduledoc """
  Typical vector operations with `[float]` List.
  When list is long, we call NIF functions to speed up computation.

  Note: What we call "vector" here is just a list of numbers of type float,
  it is not a new type.

  **Important:** Make sure **ALL** elements of vector(s) have type float before calling
  functions of this module. NIF C functions assume all elements have type float,
  they will fail (usually with "bad argument" error) if some element is not float.

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

  When vectors are long we call `nif_dot_product`.

  **Warning:** make sure all elements are float,
  `use vec = Numy.Vector.from_list(your_list)`
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

  ## Benchmarks

      iex(16)> import Numy.Vector
      iex(17)> vec = Numy.Vector.from_list(Enum.to_list(1..100))
      iex(18)> Benchee.run(%{"elixir" => fn -> dot_product(vec, vec) end, \\
      ...(18)> "C code" => fn -> nif_dot_product(vec, vec) end})
      Comparison:
      C code      173.44 K
      elixir      149.06 K - 1.16x slower +0.94 μs
      iex(19)> vec = Numy.Vector.from_list(Enum.to_list(1..1_000))
      Comparison:
      C code       24.11 K
      elixir       14.77 K - 1.63x slower +26.25 μs
      iex(24)> vec = Numy.Vector.from_list(Enum.to_list(1..99_000))
      Comparison:
      C code        248.26
      elixir         94.39 - 2.63x slower +6.57 ms
  """
  def nif_dot_product(vector1, vector2) when is_two_vectors_equal_length(vector1, vector2) do
    raise "nif_dot_product/2 not implemented"
  end

end
