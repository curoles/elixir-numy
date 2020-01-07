defmodule Numy.Lapack do
  @moduledoc """
  NIF wrapper around LAPACK.
  """

  @opaque tensor_res :: binary

  @doc """
  Numy.Lapack structure defines a tensor.
  Having tensor as NIF resource helps to bring computation to the data.

      iex> tensor = %Numy.Lapack{shape: [3,2]}
  """
  @derive {Inspect, only: [:shape]}
  @enforce_keys [:shape]
  defstruct [
    :nif_resource, # pointer to NIF resource
    :shape         # shape of tensor as list, [3, 2] - 2 rows and 3 columns
  ]


  @on_load :load_nifs

  @doc """
  Callback on module's load. Loads NIF shared library.
  """
  def load_nifs do
    path = :filename.join(:code.priv_dir(:numy), 'libnumy_lapack')
    load_res = :erlang.load_nif(path, 0)
    case load_res do
      :ok ->
        check_nif_version()
      {_error, {_reason, err_msg}} ->
        IO.puts "can't load numy_lapack.so: " <> err_msg
        :abort
      {_,e} ->
        IO.inspect e
        :abort
    end

  end

  defp check_nif_version() do
    try do
      if "#{nif_numy_version()}" != "0.1.1" do
        raise "NIF Numy version is #{nif_numy_version()}, expected 0.1.1"
      end
      :ok
    rescue
      e in RuntimeError ->
        IO.puts "exception:" <> e.message
        :abort
    end
  end

  @doc """
  Get string with Elixir Numy version at the moment of NIF compilation.
  Use it for sanity check.

  ## Examples

      iex> Numy.NIF.Lapack.numy_version
      '0.1.0'
  """
  @spec nif_numy_version() :: String.t()
  def nif_numy_version() do
    raise "nif_numy_version/0 not implemented"
  end

  @doc """
  Create new tensor NIF resource.
  """
  @spec create_tensor(%Numy.Lapack{}) :: tensor_res
  def create_tensor(_tensor_struct) do
    raise "tensor_create/1 not implemented"
  end

  def new_tensor(tensor_struct) when is_map(tensor_struct) do
    try do
      nif_resource = create_tensor(tensor_struct)
      %{tensor_struct | nif_resource: nif_resource}
    rescue
      _ -> nil
    end
  end

  def new_tensor(shape) do
    try do
      tensor_struct = %Numy.Lapack{shape: shape}
      nif_resource = create_tensor(tensor_struct)
      %{tensor_struct | nif_resource: nif_resource}
    rescue
      _ -> nil
    end
  end

  def fill_tensor(_tensor, _fill_val) do
    raise "fill/2 not implemented"
  end

  @doc """
  Fill tensor with a scalar.

  ## Examples

      iex(1)> tensor = Numy.Lapack.new_tensor([2,3])
      iex(2)> Numy.Lapack.fill(tensor, 3.14)
      iex(3)> Numy.Lapack.data(tensor)
      [3.14, 3.14, 3.14, 3.14, 3.14, 3.14]
  """
  def fill(tensor, val) when is_map(tensor) do
    try do
      fill_tensor(tensor.nif_resource, val)
    rescue
      _ ->
      :error
    end
  end

  def tensor_data(_tensor, _nelm) do
    raise "tensor_data/2 not implemented"
  end

  def data(tensor, nelm \\ -1) when is_map(tensor) do
    try do
      tensor_data(tensor.nif_resource, nelm)
    rescue
      _ ->
      :error
    end
  end

  def tensor_assign(_tensor, _list) do
    raise "tensor_assign/2 not implemented"
  end

  def assign(tensor, list) when is_map(tensor) and is_list(list) do
    try do
      tensor_assign(tensor.nif_resource, List.flatten(list))
    rescue
      _ ->
        :error
    end
  end

  @spec blas_drotg(float, float) :: {float,float,float,float}
  def blas_drotg(_a,_b) do
    raise "cblas_drotg/2 not implemented"
  end

  @doc """

      res = generate_plane_rotation(1,2)
      Keyword.fetch(res, :r | :z | :c | :s)
  """
  @spec generate_plane_rotation(number, number) :: :error | Keyword.t()
  def generate_plane_rotation(a, b) when is_number(a) and is_number(b) do
    try do
      {r, z, c, s} = blas_drotg(a/1, b/1)
      [r: r, z: z, c: c, s: s]
    rescue
      _ ->
      :error
    end
  end

  @spec blas_dcopy(number, tensor_res, number, tensor_res, number) :: number
  def blas_dcopy(_num, _src, _src_step, _dst, _dst_step) do
    raise "blas_dcopy/5 not implemented"
  end


  def lapack_dgels(_tensor_a, _tensor_b) do
    raise "lapack_dgels/2 not implemented"
  end

  def solve_lls(a, b) when is_map(a) and is_map(b) do
    cond do
      length(a.shape) != 2 ->
        :error
      length(b.shape) != 2 ->
        :error
      true ->
        try do
          lapack_dgels(a.nif_resource, b.nif_resource)
        rescue
          _ ->
            :error
        end
    end
  end

  def vector_add(_tensor_a, _tensor_b) do
    raise "vector_add/2 not implemented"
  end

  def vector_sub(_tensor_a, _tensor_b) do
    raise "vector_sub/2 not implemented"
  end

  def vector_mul(_tensor_a, _tensor_b) do
    raise "vector_mul/2 not implemented"
  end

  def vector_div(_tensor_a, _tensor_b) do
    raise "vector_div/2 not implemented"
  end

  def vector_dot(_tensor_a, _tensor_b) do
    raise "vector_dot/2 not implemented"
  end

  @doc "If all data is viewed as a vector, get element in certain position."
  def vector_at(_tensor, _index) do
    raise "vector_at/2 not implemented"
  end

  @doc "Compare elements of 2 vectors for equality"
  def vector_equal(_tensor_a, _tensor_b) do
    raise "vector_equal/2 not implemented"
  end

  @doc "Deep copy of all elements regardless of shape and data type."
  def data_copy_all(_tensor_a, _tensor_b) do
    raise "data_copy_all/2 not implemented"
  end

  def copy(tensor_dst, tensor_src) when is_map(tensor_dst) and is_map(tensor_src) do
    try do
      data_copy_all(tensor_dst.nif_resource, tensor_src.nif_resource)
    rescue
      _ -> :error
    end
  end

end


# Tz protocol implementation
#
defimpl Numy.Tz, for: Numy.Lapack do

  def ndim(tensor) do
    length(tensor.shape)
  end

  def nelm(tensor) do
    Enum.reduce(tensor.shape, 1, fn x, acc -> acc * x end)
  end

  def assign(tensor, list) do
    Numy.Lapack.assign(tensor, list)
  end

  def data(tensor, nelm \\ -1) do
    Numy.Lapack.data(tensor, nelm)
  end
end
