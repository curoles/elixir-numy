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
