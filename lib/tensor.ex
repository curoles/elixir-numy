defmodule Numy.Tensor do
  @moduledoc """
  Numy.Tensor is a multi-dimentional matrix (sometimes caled ND-Array)
  contaning elements of a single data type.

  """

  #defstruct [:resource]

  #defimpl Inspect do
    # ...
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

  def create() do
    raise "create/0 not implemented"
  end

  def nr_dimensions(_tensor) do
    raise "nr_dimentions/1 not implemented"
  end

end
