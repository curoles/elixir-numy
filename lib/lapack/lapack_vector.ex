defmodule Numy.Lapack.Vector do
  @moduledoc """
  LAPACK Vector.

  Implements protocols: `Numy.Vc`, `Numy.Vcm`

  ## Example of mutating `add!`

      iex(7)> v = Numy.Lapack.Vector.new([1,2,3])
      %Numy.Lapack.Vector{lapack: #Numy.Lapack<shape: [...], ...>, nelm: 3}
      iex(8)> Numy.Vcm.add!(v,v)
      :ok
      iex(9)> Numy.Lapack.data(v.lapack)
      [2.0, 4.0, 6.0]

  ## Example of non-mutating `add`

      iex(3)> v = Numy.Lapack.Vector.new([1,2,3])
      %Numy.Lapack.Vector{lapack: #Numy.Lapack<shape: [...], ...>, nelm: 3}
      iex(4)> Numy.Vc.add(v,v)
      [1.0, 2.0, 3.0]
  """

  @enforce_keys [:nelm]
  defstruct [
    :nelm,   # length of the vector
    :lapack  # %Numy.Lapack structure
  ]

  alias Numy.Lapack.Vector, as: LVec

  def new(nelm) when is_integer(nelm) do
    %Numy.Lapack.Vector{nelm: nelm, lapack: Numy.Lapack.new_tensor([nelm])}
  end

  def new(list) when is_list(list) do
    nelm = length(list)
    v = %Numy.Lapack.Vector{nelm: nelm, lapack: Numy.Lapack.new_tensor([nelm])}
    cond do
      v.lapack == nil -> nil
      true ->
        Numy.Lapack.assign(v.lapack, Numy.Enumy.all_to_float(list))
        v
    end
  end

  @doc "Create new Vector as a copy of other Vector"
  def new(%Numy.Lapack.Vector{nelm: sz, lapack: lpk} = _other_vec) do
    new_vec = Numy.Lapack.Vector.new(sz)
    Numy.Lapack.copy(new_vec.lapack, lpk)
    new_vec
  end

  @doc "Create new Vector from Elixir Range"
  def new(%Range{} = range) do
    new(Enum.to_list(range))
  end

  @doc """
  Create new Vector as a concatination of 2 other vectors

  ## Examples

      iex(1)> v1 = Numy.Lapack.Vector.new([1,2,3])
      iex(2)> v2 = Numy.Lapack.Vector.new([4,5,6])
      iex(3)> v3 = Numy.Lapack.Vector.new(v1,v2)
      iex(4)> Numy.Vc.data(v3)
      [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
  """
  def new(%Numy.Lapack.Vector{nelm: sz1, lapack: lpk1} = _v1,
          %Numy.Lapack.Vector{nelm: sz2, lapack: lpk2} = _v2) do
    new_vec = Numy.Lapack.Vector.new(sz1 + sz2)
    Numy.Lapack.copy(new_vec.lapack, lpk1)
    Numy.Lapack.vector_copy_range(new_vec.lapack.nif_resource, lpk2.nif_resource,
        sz2, sz1, 0, 1, 1)
    new_vec
  end

  def make_from_nif_res(res) do
    nrelm = Numy.Lapack.tensor_nrelm(res);
    %Numy.Lapack.Vector{nelm: nrelm, lapack: %Numy.Lapack{nif_resource: res, shape: [nrelm]}}
  end

  def save_to_file(v, filename) when is_map(v) do
    Numy.Lapack.tensor_save_to_file(v.lapack.nif_resource, filename)
  end

  @doc """

  ## Examples

      iex(4)> v = Numy.Lapack.Vector.new(1..100)
      #Vector<size=100, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, ...]>
      iex(5)> Numy.Lapack.Vector.save_to_file(v, 'vec.numy.bin')
      :ok
      iex(6)> Numy.Lapack.Vector.load_from_file('vec.numy.bin')
      #Vector<size=100, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, ...]>
  """
  def load_from_file(filename) do
    res = Numy.Lapack.tensor_load_from_file(filename)
    make_from_nif_res(res)
  end


  defimpl Numy.Vc do

    def assign_all(v, val) when is_map(v) and is_number(val) do
      Numy.Lapack.vector_assign_all(v.lapack.nif_resource, val)
      v
    end

    def assign_zeros(v) when is_map(v) do
      Numy.Lapack.vector_assign_all(v.lapack.nif_resource, 0.0)
      v
    end

    def assign_ones(v) when is_map(v) do
      Numy.Lapack.vector_assign_all(v.lapack.nif_resource, 1.0)
      v
    end

    def assign_random(v) when is_map(v) do
      Numy.Lapack.assign(v.lapack, Numy.Float.make_list_randoms(v.nelm))
      v
    end

    def data(v, nelm) when is_map(v) and is_integer(nelm) do
      Numy.Lapack.data(v.lapack, nelm)
    end

    def at(%Numy.Lapack.Vector{nelm: nelm}, index, default) when index < 0 or index >= nelm, do: default
    def at(v, index, _default) when is_map(v) and is_integer(index) do
      Numy.Lapack.vector_get_at(v.lapack.nif_resource, index)
    end

    def empty?(v) when is_map(v) do
      v.nelm == 0
    end

    @doc "Return size/length of the vector."
    def size(v) when is_map(v) do
      v.nelm
    end

    def equal?(v1,v2) when is_map(v1) and is_map(v2) do
      Numy.Lapack.vector_equal(v1.lapack.nif_resource, v2.lapack.nif_resource)
    end

    @doc """
    Add two vectors.

    ## Examples

        iex(5)> v = Numy.Lapack.Vector.new([1,2,3])
        %Numy.Vector{data: [1.0, 2.0, 3.0], nelm: 3}
        iex(6)> Numy.Vc.add(v, v)
        %Numy.Vector{data: [2.0, 4.0, 6.0], nelm: 3}
    """
    def add(v1, v2) when is_map(v1) and is_map(v2) do
      Numy.Vcm.add!(LVec.new(v1), v2)
    end

    def sub(v1, v2) when is_map(v1) and is_map(v2) do
      Numy.Vcm.sub!(LVec.new(v1), v2)
    end

    def mul(v1, v2) when is_map(v1) and is_map(v2) do
      Numy.Vcm.mul!(LVec.new(v1), v2)
    end

    def div(v1, v2) when is_map(v1) and is_map(v2) do
      Numy.Vcm.div!(LVec.new(v1), v2)
    end

    def scale(v, factor) when is_map(v) and is_number(factor) do
      Numy.Vcm.scale!(LVec.new(v), factor)
    end

    def offset(v, off) when is_map(v) and is_number(off) do
      Numy.Vcm.offset!(LVec.new(v), off)
    end

    def negate(v) when is_map(v) do
      Numy.Vcm.negate!(LVec.new(v))
    end

    def dot(v1, v2) when is_map(v1) and is_map(v2) do
      Numy.Lapack.vector_dot(v1.lapack.nif_resource, v2.lapack.nif_resource)
    end

    @doc "Sum of all elements, ∑aᵢ"
    def sum(v) do
      Numy.Lapack.vector_sum(v.lapack.nif_resource)
    end

    @doc "Average (∑aᵢ)/length"
    def mean(%Numy.Vector{nelm: nelm, data: _}) when nelm == 0 do
      raise "empty vector";
    end
    def average(%Numy.Vector{nelm: nelm, data: _} = v) do
      Numy.Vc.sum(v) / nelm
    end

    @doc "Return max value"
    def max(v) when is_map(v) do
      Numy.Lapack.vector_max(v.lapack.nif_resource)
    end

    @doc "Return min value"
    def min(v) when is_map(v) do
      Numy.Lapack.vector_min(v.lapack.nif_resource)
    end

    @doc "Return index of max value"
    def max_index(v) when is_map(v) do
      Numy.Lapack.vector_max_index(v.lapack.nif_resource)
    end

    @doc "Return index of min value"
    def min_index(v) when is_map(v) do
      Numy.Lapack.vector_min_index(v.lapack.nif_resource)
    end

    @doc "Step function, aᵢ ← 0 if aᵢ < 0 else 1"
    def apply_heaviside(v, cutoff \\ 0.0) when is_map(v) and is_number(cutoff) do
      Numy.Vcm.apply_heaviside!(LVec.new(v), cutoff)
    end

    @doc "f(x) = 1/(1 + e⁻ˣ)"
    def apply_sigmoid(v) when is_map(v) do
      Numy.Vcm.apply_sigmoid!(LVec.new(v))
    end

    def sort(v) when is_map(v) do
      Numy.Vcm.sort!(LVec.new(v))
    end

    def reverse(v) when is_map(v) do
      Numy.Vcm.reverse!(LVec.new(v))
    end

    @doc "Concatenate 2 vectors"
    def concat(v1,v2) when is_map(v1) and is_map(v2) do
      Numy.Lapack.Vector.new(v1,v2)
    end

    def find(v,val) when is_map(v) and is_number(val) do
      Numy.Lapack.vector_find(v.lapack.nif_resource,val)
    end

    def contains?(v,val) when is_map(v) and is_number(val) do
      Numy.Vc.find(v,val) != -1
    end

  end # defimpl Numy.Vc


  defimpl Numy.Vcm do

    def add!(v1,v2) when is_map(v1) and is_map(v2) do
      try do
        Numy.Lapack.vector_add(v1.lapack.nif_resource, v2.lapack.nif_resource)
        v1
      rescue
        _ -> :error
      end
    end

    def sub!(v1,v2) when is_map(v1) and is_map(v2) do
      try do
        Numy.Lapack.vector_sub(v1.lapack.nif_resource, v2.lapack.nif_resource)
        v1
      rescue
        _ -> :error
      end
    end

    def mul!(v1,v2) when is_map(v1) and is_map(v2) do
      try do
        Numy.Lapack.vector_mul(v1.lapack.nif_resource, v2.lapack.nif_resource)
        v1
      rescue
        _ -> :error
      end
    end

    def div!(v1,v2) when is_map(v1) and is_map(v2) do
      try do
        Numy.Lapack.vector_div(v1.lapack.nif_resource, v2.lapack.nif_resource)
        v1
      rescue
        _ -> :error
      end
    end

    def scale!(v, factor) when is_map(v) and is_number(factor) do
      try do
        Numy.Lapack.vector_scale(v.lapack.nif_resource, factor)
        v
      rescue
        _ -> :error
      end
    end

    @spec offset!(map, number) :: :error
    def offset!(v, factor) when is_map(v) and is_number(factor) do
      try do
        Numy.Lapack.vector_offset(v.lapack.nif_resource, factor)
        v
      rescue
        _ -> :error
      end
    end

    def negate!(v) when is_map(v) do
      try do
        Numy.Lapack.vector_negate(v.lapack.nif_resource)
        v
      rescue
        _ -> :error
      end
    end

    def apply_heaviside!(v, cutoff \\ 0.0) when is_map(v) and is_number(cutoff) do
      try do
        Numy.Lapack.vector_heaviside(v.lapack.nif_resource, cutoff)
        v
      rescue
        _ -> :error
      end
    end

    def apply_sigmoid!(v) when is_map(v) do
      try do
        Numy.Lapack.vector_sigmoid(v.lapack.nif_resource)
        v
      rescue
        _ -> :error
      end
    end

    def sort!(v) when is_map(v) do
      try do
        Numy.Lapack.vector_sort(v.lapack.nif_resource)
        v
      rescue
        _ -> :error
      end
    end

    def reverse!(v) when is_map(v) do
      try do
        Numy.Lapack.vector_reverse(v.lapack.nif_resource)
        v
      rescue
        _ -> :error
      end
    end

    def set_at!(v, pos, val) when is_map(v) and is_integer(pos) and is_number(val) do
      try do
        Numy.Lapack.vector_set_at(v.lapack.nif_resource, pos, val)
        v
      rescue
        _ -> :error
      end
    end

    def axpby!(v1, v2, f1, f2) when is_map(v1) and is_map(v2) and
    is_number(f1) and is_number(f2) do
      try do
        Numy.Lapack.vector_axpby(v1.lapack.nif_resource, v1.lapack.nif_resource, f1, f2)
        v1
      rescue
        _ -> :error
      end
    end

  end # defimpl Numy.Vcm


  @doc """

  ## Examples

      iex(1)> alias Numy.Lapack.Vector
      Numy.Lapack.Vector
      iex(2)> a = Vector.new(1..10)
      #Vector<size=10, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]>
      iex(3)> b = Vector.new(1..10)
      #Vector<size=10, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]>
      iex(4)> Vector.swap_ranges(a,b,3,2,7)
      :ok
      iex(5)> a
      #Vector<size=10, [1.0, 2.0, 8.0, 9.0, 10.0, 6.0, 7.0, 8.0, 9.0, 10.0]>
      iex(6)> b
      #Vector<size=10, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 3.0, 4.0, 5.0]>
  """
  def swap_ranges(v1, v2, nelm, off_a, off_b) do
    Numy.Lapack.vector_swap_ranges(v1.lapack.nif_resource, v2.lapack.nif_resource,
      nelm, off_a, off_b)
  end
end

defimpl Inspect, for: Numy.Lapack.Vector do
  import Inspect.Algebra

  def inspect(v, opts) do
    opts = %{opts | limit: 10}
    concat(["#Vector<size=", to_doc(v.nelm, opts), ", ",
      to_doc(Numy.Vc.data(v), opts), ">"])
  end
end

defimpl Numy.Set, for: Numy.Lapack.Vector do
  @doc """
  The union of two sets is formed by the elements that are present
  in either one of the sets, or in both.

  C = A ∪ B = {x : x ∈ A or x ∈ B}
  """
  def union(a, b) when is_map(a) and is_map(b) do
    res = Numy.Lapack.set_op(a.lapack.nif_resource, b.lapack.nif_resource, :union)
    Numy.Lapack.Vector.make_from_nif_res(res)
  end

  @doc """
  The intersection of two sets is formed only by the elements
  that are present in both sets.

  C = A ∩ B = {x : x ∈ A and x ∈ B}
  """
  def intersection(a, b) when is_map(a) and is_map(b) do
    res = Numy.Lapack.set_op(a.lapack.nif_resource, b.lapack.nif_resource, :intersection)
    Numy.Lapack.Vector.make_from_nif_res(res)
  end

  @doc """
  The difference of two sets is formed by the elements
  that are present in the first set, but not in the second one.
  """
  def diff(a, b) when is_map(a) and is_map(b) do
    res = Numy.Lapack.set_op(a.lapack.nif_resource, b.lapack.nif_resource, :diff)
    Numy.Lapack.Vector.make_from_nif_res(res)
  end

  @doc """
  The symmetric difference of two sets is formed by the elements
  that are present in one of the sets, but not in the other.
  """
  def symm_diff(a, b) when is_map(a) and is_map(b) do
    res = Numy.Lapack.set_op(a.lapack.nif_resource, b.lapack.nif_resource, :symm_diff)
    Numy.Lapack.Vector.make_from_nif_res(res)
  end
end
