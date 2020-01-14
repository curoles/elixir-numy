


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
