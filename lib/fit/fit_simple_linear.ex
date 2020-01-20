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
    sum_sq_dx = Vc.clone(x) |> Vcm.offset!(-x_mean) |> Vcm.pow2! |> Vc.sum
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
    dx = Vc.clone(x) |> Vcm.offset!(-x_mean)
    dy = Vc.clone(y) |> Vcm.offset!(-y_mean)
    Vc.dot(dx,dy)
  end

  def covariance_over_variance(x,y) do
    x_mean = Vc.mean(x)
    y_mean = Vc.mean(y)
    dx = Vc.clone(x) |> Vcm.offset!(-x_mean)
    dy = Vc.clone(y) |> Vcm.offset!(-y_mean)
    cov = Vc.dot(dx,dy)
    sum_sq_dx = dx |> Vcm.pow2! |> Vc.sum
    var = sum_sq_dx / (Vc.size(x) - 1)
    cov / var
  end

  #@doc """
  #Return value in range [0,1], where 1 means perfect prediction, 0 indicates a prediction that is worse than the mean (???)
  #"""
  #def fit_quality(predicted, actual) do
  #  d = Vector.Distance.pearson(predicted, actual)
  #  d * d
  #end

end
