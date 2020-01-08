defprotocol Numy.Tz do
  @moduledoc """
  Interface to Tensor.
  """

  @doc """
  Get number of dimensions

  ## Examples

      iex(1)> tensor = Numy.Lapack.new_tensor([1,2,3,4,5])
      iex(2)> Numy.Tz.ndim(tensor)
      5
      iex(3)> Numy.Tz.nelm(tensor)
      120
  """
  def ndim(tensor)

  @doc """
  Get number of elements
  """
  def nelm(tensor)

  def assign(tensor, list)

  def data(tensor, nelm \\ -1)
end

defprotocol Numy.Mx do
  @moduledoc """
  Interface to Matrix
  """
end

defprotocol Numy.Vc do
  @moduledoc """
  Interface to Vector
  """

  @doc "Assign 0.0 to each element of the vector."
  def assign_zeros(v)
  @doc "Assign 1.0 to each element of the vector."
  def assign_ones(v)
  @doc "Assign random values to the elements."
  def assign_random(v)

  @doc "Return true if vector is empty."
  def empty?(v)

  @doc "Get data as a list"
  def data(v)
  @doc "Get value of N-th element by index, return default in case of error."
  def at(v, index, default \\ nil)

  @doc "Check if elements of 2 vectors are practically the same."
  def equal?(v1,v2)

  @doc "Add 2 vectors, cᵢ ← aᵢ + bᵢ"
  def add(v1, v2)
  @doc "Subtract one vector from other, cᵢ ← aᵢ - bᵢ"
  def sub(v1, v2)
  @doc "Multiply 2 vectors, cᵢ ← aᵢ×bᵢ"
  def mul(v1, v2)
  @doc "Divide 2 vectors, cᵢ ← aᵢ÷bᵢ"
  def div(v1, v2)

  @doc "Multiply each element by a constant, aᵢ ← aᵢ×scale_factor"
  def scale(v, factor)
  @doc "Add a constant to each element, aᵢ ← aᵢ + offset"
  def offset(v, off)

  @doc "Dot product of 2 vectors, ∑aᵢ×bᵢ"
  def dot(v1, v2)

  @doc "Sum of all elements, ∑aᵢ"
  def sum(v)
  @doc "Average (∑aᵢ)/length"
  def average(v)

  @doc "Return max value"
  def max(v)
  @doc "Return min value"
  def min(v)

  @doc "Return index of max value"
  def max_index(v)
  @doc "Return index of min value"
  def min_index(v)

  @doc "Step function, aᵢ ← 0 if aᵢ < 0 else 1"
  def apply_heaviside(v, cutoff \\ 0.0)
  @doc "f(x) = 1/(1 + e⁻ˣ)"
  def apply_sigmoid(v)

  @doc "Sort elements"
  def sort(v)
end

defprotocol Numy.Vcm do
  @moduledoc """
  Interface to mutable Vector.

  Native objects do not follow Elixir/Erlang model where an object
  is always immutable. We purposefully allow native objects to be mutable
  in order to get better performance in numerical computing.
  """

  @doc """
  Mutate a vector by adding other to it, v1 = v1 + v2.
  Return mutated vector.
  """
  def add!(v1, v2)

  def sub!(v1, v2)
  def mul!(v1, v2)
  def div!(v1, v2)

  @doc "Multiply each element by a constant, aᵢ ← aᵢ×scale_factor"
  def scale!(v, factor)
  @doc "Add a constant to each element, aᵢ ← aᵢ + offset"
  def offset!(v, off)

  @doc "Step function, aᵢ ← 0 if aᵢ < 0 else 1"
  def apply_heaviside!(v, cutoff \\ 0.0)
  @doc "f(x) = 1/(1 + e⁻ˣ)"
  def apply_sigmoid!(v)

  @doc "Sort elements of vector in-place"
  def sort!(v)
end
