defprotocol Numy.Tz do
  @moduledoc """
  Interface to Tensor.
  """

  @doc """
  Get number of dimensions

  ## Examples

      iex> tensor = Numy.Tensor.new([1,2,3,4])
      iex> Numy.Tz.ndim(tensor)
      4
  """
  def ndim(tensor)

  @doc """
  Get number of elements
  """
  #def nelm(tensor)
end
