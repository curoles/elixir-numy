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

  def assign_zeros(v)
  def assign_ones(v)
  def assign_random(v)

  def at(v, index, default)
  def empty?(v)

  def close?(v1,v2)

  def add(v1, v2)
  def sub(v1, v2)
  def multiply(v1, v2)

  def scale(v, factor)

  def dot(v1, v2)
end

defprotocol Numy.Vcm do
  @moduledoc """
  Interface to mutable Vector.
  """

  def add!(v1, v2)

end
