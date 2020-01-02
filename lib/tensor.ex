defmodule Numy.Tensor do
  @moduledoc """
  Numy.Tensor is a multi-dimentional matrix (sometimes caled ND-Array)
  contaning elements of a single data type.

  """

  @opaque tensor_res :: binary

  # Struct gets its name from the containing it module.
  @doc """
  Structure Tensor is opaque type for NIF structure.

      iex> my_tensor = %Numy.Tensor{shape: [3,2]}
  """
  @derive {Inspect, only: [:shape]}
  @enforce_keys [:shape]
  defstruct [
    :nif_resource, # pointer to NIF resource
    :shape         # shape of tensor as list, [3, 2] - 2 rows and 3 columns
  ]

  #defimpl Inspect do
  #  import Inspect.Algebra

  #  def inspect(tensor_struct, opts) do
  #    concat(["#Tensor<", to_doc(???tensor_struct, opts), ">"])
  #  end
  #end

  @on_load :load_nifs

  @doc """
  Callback on module's load. Loads NIF shared library.
  """
  def load_nifs do
    mix_app = Mix.Project.config[:app]
    path = :filename.join(:code.priv_dir(mix_app), 'libnumy_tensor')
    :erlang.load_nif(path, 0)
  end

  @spec create(%Numy.Tensor{}) :: tensor_res
  def create(_tensor_struct) do
    raise "create/1 not implemented"
  end

  def new(tensor_struct) when is_map(tensor_struct) do
    try do
      nif_resource = create(tensor_struct)
      %{tensor_struct | nif_resource: nif_resource}
    rescue
      _ -> nil
    end
  end

  def new(shape) do
    try do
      tensor_struct = %Numy.Tensor{shape: shape}
      nif_resource = create(tensor_struct)
      %{tensor_struct | nif_resource: nif_resource}
    rescue
      _ -> nil
    end
  end

  @doc """

  ## Examples

      iex(1)> tensor_def = %Numy.Tensor{shape: [2,3]}
      #Numy.Tensor<shape: [...], ...>
      iex(2)> tensor = Numy.Tensor.create(tensor_def)
      #Reference<0.2043608959.3639214083.153022>
      iex(3)> Numy.Tensor.nr_dimensions(tensor)
      2
  """
  @spec nr_dimensions(tensor_res) :: pos_integer
  def nr_dimensions(_tensor) do
    raise "nr_dimentions/1 not implemented"
  end

end

# Tz protocol implementation
#
#defimpl Numy.Tz, for: Numy.Tensor do
#
#  def ndim(tensor) do
#    try do
#      Numy.Tensor.nr_dimensions(tensor.nif_resource)
#    rescue
#      _ -> 0
#    end
#  end
#
#  #def nelm(_tensor) do
#  #  1 # TODO Numy.Tensor.nr_elements(tensor)
#  #end
#end
