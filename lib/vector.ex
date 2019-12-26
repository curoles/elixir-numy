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

  @doc """
  Multiply each element of vector by scalar constant factor.
  For long vectors scaling is done in parallel with Flow.

  ## Examples

      iex(2)> scale([2.0,3.0,4.0], 0.5)
      [1.0, 1.5, 2.0]

  ## Benchmarks

      iex> import Numy.Vector
      iex> vec1 = Enum.to_list(1..1000) |> from_list
      iex> vec10 = Enum.to_list(1..10_000) |> from_list
      iex> vec99 = Enum.to_list(1..99_000) |> from_list
      iex> vec101 = Enum.to_list(1..101_000) |> from_list
      iex> vec999 = Enum.to_list(1..999_000) |> from_list
      iex(7)> Benchee.run(%{"1" => fn -> scale(vec1, 0.5) end,
      ...(7)> "10" => fn -> scale(vec10, 0.5) end,
      ...(7)> "99" => fn -> scale(vec99, 0.5) end,
      ...(7)> "101" => fn -> scale(vec101, 0.5) end,
      ...(7)> "999" => fn -> scale(vec999, 0.5) end})
      Name           ips        average  deviation         median         99th %
      1          18.09 K       55.27 μs    ±22.13%       52.30 μs       87.83 μs
      10          1.57 K      635.89 μs     ±4.67%      624.25 μs      742.20 μs
      99         0.109 K     9188.89 μs    ±10.06%     8978.82 μs    13769.76 μs
      101 FLOW    2.10 K      475.69 μs    ±12.76%      460.00 μs      615.74 μs
      999        0.176 K     5686.61 μs     ±2.77%     5667.13 μs     6261.60 μs
  """
  @spec scale([float], float) :: [float]
  def scale(vector, factor) when length(vector) < 100_000 do
    Enum.map(vector, fn x -> x * factor end)
  end
  def scale(vector, factor) do
    vector |> Flow.from_enumerable() |> Flow.map(fn x -> x * factor end)
  end

  @doc """

  ## Examples

      iex(5)> add([1.0,2.0,3.0],[2.0,3.0,4.0])
      [3.0, 5.0, 7.0]
  """
  @spec add([float], [float]) :: [float]
  def add(vec1, vec2) when vec1 == [] or vec2 == [], do: []
  def add(vec1, vec2) when length(vec1) < 10_000 do
    Enum.zip(vec1,vec2) |> Enum.map(fn {a,b} -> a + b end)
  end
  def add(vec1, vec2) do
    Enum.zip(vec1,vec2) |> Flow.from_enumerable |> Flow.map(fn {a,b} -> a + b end)
  end

  @spec subtract([float], [float]) :: [float]
  def subtract(vec1, vec2) when vec1 == [] or vec2 == [], do: []
  def subtract(vec1, vec2) when length(vec1) < 10_000 do
    Enum.zip(vec1,vec2) |> Enum.map(fn {a,b} -> a - b end)
  end
  def subtract(vec1, vec2) do
    Enum.zip(vec1,vec2) |> Flow.from_enumerable |> Flow.map(fn {a,b} -> a - b end)
  end

  @spec element_multiply([float], [float]) :: [float]
  def element_multiply(vec1, vec2) when vec1 == [] or vec2 == [], do: []
  def element_multiply(vec1, vec2) when length(vec1) < 10_000 do
    Enum.zip(vec1,vec2) |> Enum.map(fn {a,b} -> a - b end)
  end
  def element_multiply(vec1, vec2) do
    Enum.zip(vec1,vec2) |> Flow.from_enumerable |> Flow.map(fn {a,b} -> a * b end)
  end

end
