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
  @doc "Assign some value to all elements."
  def assign_all(v, val)

  @doc "Return true if vector is empty."
  def empty?(v)

  @doc "Get data as a list"
  def data(v, nelm \\ -1)
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
  @doc "Change sign of each element, aᵢ ← -aᵢ"
  def negate(v)

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
  @doc "Reverse"
  def reverse(v)

  @doc "Concatenate 2 vectors"
  def concat(v1,v2)

  @doc "Find value in vector, returns position, -1 if could not find"
  def find(v,val)

  @doc "Return true if vector contains the value"
  def contains?(v,val)
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
  @doc "Change sign of each element, aᵢ ← -aᵢ"
  def negate!(v)

  @doc "Step function, aᵢ ← 0 if aᵢ < 0 else 1"
  def apply_heaviside!(v, cutoff \\ 0.0)
  @doc "f(x) = 1/(1 + e⁻ˣ)"
  def apply_sigmoid!(v)

  @doc "Sort elements of vector in-place"
  def sort!(v)
  @doc "Reverse elements of vector in-place"
  def reverse!(v)

  @doc "Set N-th element to a new value"
  def set_at!(v, index, val)

  @doc "aᵢ ← aᵢ×factor_a + bᵢ×factor_b"
  def axpby!(v1, v2, f1, f2)
end

defprotocol Numy.Set do
  @moduledoc """
  Set operations.

  Assuming vector-like container with floats.

  ## Examples

      iex(6)> a = Numy.Lapack.Vector.new(1..5)
      #Vector<size=5, [1.0, 2.0, 3.0, 4.0, 5.0]>
      iex(7)> b = Numy.Lapack.Vector.new(5..10)
      #Vector<size=6, [5.0, 6.0, 7.0, 8.0, 9.0, 10.0]>
      iex(8)> Numy.Set.union(a,b)
      #Vector<size=10, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]>
      iex(9)> Numy.Set.intersection(a,b)
      #Vector<size=1, [5.0]>
      iex(10)> Numy.Set.diff(a,b)
      #Vector<size=4, [1.0, 2.0, 3.0, 4.0]>
      iex(11)> Numy.Set.symm_diff(a,b)
      #Vector<size=9, [1.0, 2.0, 3.0, 4.0, 6.0, 7.0, 8.0, 9.0, 10.0]>
  """

  @doc """
  The union of two sets is formed by the elements that are present
  in either one of the sets, or in both.

  C = A ∪ B = {x : x ∈ A or x ∈ B}
  """
  def union(a, b)

  @doc """
  The intersection of two sets is formed only by the elements
  that are present in both sets.

  C = A ∩ B = {x : x ∈ A and x ∈ B}
  """
  def intersection(a, b)

  @doc """
  The difference of two sets is formed by the elements
  that are present in the first set, but not in the second one.
  """
  def diff(a, b)

  @doc """
  The symmetric difference of two sets is formed by the elements
  that are present in one of the sets, but not in the other.
  """
  def symm_diff(a, b)
end
