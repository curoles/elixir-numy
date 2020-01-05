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

  def empty?(v)

  @doc "Get data as a list"
  def data(v)
  def at(v, index, default)

  def close?(v1,v2)

  def add(v1, v2)
  def sub(v1, v2)
  def mul(v1, v2)
  #def div(v1, v2)

  def scale(v, factor)

  def dot(v1, v2)
end

defprotocol Numy.Vcm do
  @moduledoc """
  Interface to mutable Vector.

  Native objects do not follow Elixir/Erlang model where an object
  is always immutable. We purposefully allow native objects to be mutable
  in order to get better performance in numerical computing.
  """

  @doc """
  Add two vectors, v1 = v1 + v2.
  """
  def add!(v1, v2)

end
