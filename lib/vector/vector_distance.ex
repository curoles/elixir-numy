defmodule Numy.Vector.Distance do
  @moduledoc """
  Distance between 2 points (vectors) in N-dimentional space.

  Each element of a vector of size N defines a coordinate
  in N-dimentional space.
  """

  alias Numy.Vc
  alias Numy.Vcm


  @doc """

  ## Example

      iex(45)> x = Numy.Lapack.Vector.new([1,1])
      #Vector<size=2, [1.0, 1.0]>
      iex(46)> y = Numy.Lapack.Vector.new([4,5])
      #Vector<size=2, [4.0, 5.0]>
      iex(47)> Numy.Vector.Distance.manhatten(x,y)
      7.0
  """
  def manhatten(x,y) do
    Vc.sub(x,y) |>
    Vcm.abs!    |>
    Vc.sum
  end

  @doc """

  ## Example

      iex(45)> x = Numy.Lapack.Vector.new([1,1])
      #Vector<size=2, [1.0, 1.0]>
      iex(46)> y = Numy.Lapack.Vector.new([4,5])
      #Vector<size=2, [4.0, 5.0]>
      iex(49)> Numy.Vector.Distance.euclidean(x,y)
      5.0 # (4-1)^2 + (5-1)^2 = 9 + 16 = 25
  """
  def euclidean(x,y) do
    Vc.sub(x,y) |>
    Vc.norm2
  end

  @doc """
  https://en.wikipedia.org/wiki/Minkowski_distance
  """
  def minkowski(x,y,p \\ 3) do
    Vc.sub(x,y) |>
    Vcm.abs!    |>
    Vcm.pow!(p) |>
    Vc.sum      |>
    :math.pow(1/p)
  end

  def mean_sq_error(x,y) do
    Vc.sub(x,y) |>
    Vcm.pow2!   |>
    Vc.mean
  end

  def root_mean_sq_error(x,y) do
    :math.sqrt(mean_sq_error(x,y))
  end

  @doc """
  Pearson's correlation coefficient is the covariance of the two variables
  divided by the product of their standard deviations.

  A value of 1 implies that a linear equation describes the relationship
  between X and Y perfectly, with all data points lying on a line
  for which Y increases as X increases.
  A value of 0 implies that there is no linear correlation between the variables.
  """
  def pearson(x,y) do
    x_mean = Vc.mean(x)
    y_mean = Vc.mean(y)
    dx = Vc.offset(x,-x_mean)
    dy = Vc.offset(y,-y_mean)
    Vc.dot(dx,dy) / (Vc.norm2(dx) * Vc.norm2(dy))
  end

  #def jaccard(x,y) do
  #  1.0 - Numy.Set.jaccard_index(Vc.clone(x), Vc.clone(y))
  #end
end
