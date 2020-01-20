defmodule Numy.Vector.Distance do
  @moduledoc """
  Distance between 2 points (vectors) in N-dimentional space.

  Each element of a vector of size N defines a coordinate
  in N-dimentional space.
  """

  alias Numy.Vc
  alias Numy.Vcm


  #def manhatten(x,y) do
  #  Vc.sub(x-y) |>
  #  Vcm.abs!    |>
  #  Vc.sum
  #end

  #def euclidean(x,y) do
  #  Vc.sub(x-y) |>
  #  Vc.norm2
  #end

  @doc """
  https://en.wikipedia.org/wiki/Minkowski_distance
  """
  #def minkowski(x,y,p \\ 3) do
  #  Vc.sub(x-y) |>
  #  Vcm.abs!    |>
  #  Vcm.pow!(p) |>
  #  Vc.sum      |>
  #  :math.pow(1/p)
  #end

  #def mean_sq_error(x,y) do
  #  Vc.sub(x-y) |>
  #  Vcm.pow2!   |>
  #  Vc.mean
  #end

  #def root_mean_sq_error(x,y) do
  #  :math.sqrt(mean_sq_error)
  #end

  #def pearson(x,y) do
  #  x_mean = Vc.mean(x)
  #  y_mean = Vc.mean(y)
  #  dx = Vc.sub(x - x_mean)
  #  dy = Vc.sub(y - y_mean)
  #  cov = Vc.dot(dx,dy)
  #  sx = Vc.norm2(dx)
  #  sy = Vc.norm2(dy)
  #  cov / (sx * sy)
  #end

  #def jaccard(x,y) do
  #  1.0 - Numy.Set.jaccard_index(Vc.clone(x), Vc.clone(y))
  #end
end
