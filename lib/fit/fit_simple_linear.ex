defmodule Numy.Fit.SimpleLinear do
  @moduledoc """
  Simple Linear Regression.

  In y = α + βx, one approach to estimating the unknowns α and β is
  to consider the sum of squared residuals function, or SSR.

  >
  > ∑rᵢ² = ∑(yᵢ - α - βxᵢ)²
  >

  It is a fact that among all possible α and β, the following
  values minimize the SSR:

  > β = cov(x,y) / var(x)
  > α = ȳ - βx̄
  >

  ## Example

      iex(34)> x = Numy.Lapack.Vector.new(0..9)
      #Vector<size=10, [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]>
      iex(35)> y = Vc.scale(x,2) |> Vcm.offset!(-3.0) # make slope=2 and intercept=-3
      #Vector<size=10, [-3.0, -1.0, 1.0, 3.0, 5.0, 7.0, 9.0, 11.0, 13.0, 15.0]>
      iex(36)> err = Numy.Lapack.Vector.new(10) |> Vc.assign_random |> Vcm.offset!(-0.5) |> Vcm.scale!(0.1)
      iex(37)> Vcm.add!(y,err) # add errors to the ideal line
      iex(38)> line = Numy.Fit.SimpleLinear.fit(x,y)
      {-2.9939933270609496, 1.9966330251198818} # got intercept=-3 and slope=2 as expected
      {-2.9939933270609496, 1.9966330251198818}
      iex(40)> Numy.Fit.SimpleLinear.predict(0,line)
      -2.9939933270609496
      iex(41)> Numy.Fit.SimpleLinear.predict(10,line)
      16.97233692413787
  """

  alias Numy.Vc
  alias Numy.Vcm

  def predict(x, {intercept, slope}) when is_number(x) do
    intercept + slope * x
  end

  def fit(x,y) do
    if Vc.size(x) != Vc.size(y), do: raise ArgumentError, message: "vectors must have the same size"
    x_mean = Vc.mean(x)
    y_mean = Vc.mean(y)
    slope = covariance_over_variance(x,y)
    intercept = y_mean - slope * x_mean
    {intercept, slope}
  end

  @doc """
  In statistics, [variance](https://en.wikipedia.org/wiki/Variance)
  is the expectation of the squared deviation of a random
  variable from its mean.

  var(x) = E[ (x - x̄)² ] = (∑(xᵢ - x̄)²) / n
  """
  def variance(x) do
    x_mean = Vc.mean(x)
    sum_sq_dx = Vc.offset(x,-x_mean) |> Vcm.pow2! |> Vc.sum
    sum_sq_dx / (Vc.size(x) - 1)
  end


  @doc """
  In statistics, [covariance](https://en.wikipedia.org/wiki/Covariance)
  is a measure of the joint variability of 2 random variables.

  Here is two-pass [stable algorithm](https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Covariance)
  """
  def covariance(x,y) do
    x_mean = Vc.mean(x)
    y_mean = Vc.mean(y)
    dx = Vc.offset(x,-x_mean)
    dy = Vc.offset(y,-y_mean)
    Vc.dot(dx,dy) / (Vc.size(x) - 1)
  end

  def covariance_over_variance(x,y) do
    x_mean = Vc.mean(x)
    y_mean = Vc.mean(y)
    dx = Vc.offset(x,-x_mean)
    dy = Vc.offset(y,-y_mean)
    cov = Vc.dot(dx,dy)
    sum_sq_dx = dx |> Vcm.pow2! |> Vc.sum
    var = sum_sq_dx
    cov / var
  end

  #@doc """
  #Return value in range [0,1], where 1 means perfect prediction,
  #0 indicates a prediction that is worse than the mean (???)
  #"""
  #def fit_quality(predicted, actual) do
  #  d = Vector.Distance.pearson(predicted, actual)
  #  d * d
  #end

end
