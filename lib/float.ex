defmodule Numy.Float do
  @moduledoc """
  Floating point number utilities.
  """

  @spec from_number(number) :: float
  def from_number(n) do
    n / 1 # idiomatic way to convert a number to float
  end

  @spec sign(number) :: -1 | 0 | 1
  def sign(0), do: 0
  def sign(0.0), do: 0
  def sign(x) when x < 0, do: -1
  def sign(_), do: 1

  @doc """
  Return `true` if sign bit is 1 in the binary representation of the number.

  IEEE Long Real 64-bit binary format:

  - 1 bit for the sign,
  - 11 bits for the exponent,
  - and 52 bits for the mantissa
  """
  @spec signbit(float) :: boolean
  def signbit(x) when is_float(x) do
    case <<x :: float>> do
      <<1 :: 1, _ :: bitstring>> -> true
      _ -> false
    end
  end

  @doc """
  Convert bit-by-bit 64-bit float to 64-bit integer.
  """
  @spec as_uint64(float) :: non_neg_integer
  def as_uint64(x) when is_float(x) do
    <<uint64 :: 64>> = <<x :: float>>
    uint64
  end

  @spec copysignbit(float, float) :: float
  def copysignbit(src, dst) when is_float(src) and is_float(dst) do
    <<_ :: 1, dst_rest :: bitstring>> = <<dst :: float>>
    <<src_sign :: 1, _ :: bitstring>> = <<src :: float>>

    <<ret :: float>> = <<src_sign :: 1, dst_rest :: bitstring>>
    ret
  end

  @doc """
  Equality comparison for floating point numbers.

  Based on [this blog post](
    https://randomascii.wordpress.com/2012/02/25/comparing-floating-point-numbers-2012-edition/)
  by Bruce Dawson.
  """
  @spec close?(number, number, float, non_neg_integer) :: boolean
  def close?(a, b, epsilon \\ 1.0e-9, max_ulps \\ 1) when is_integer(max_ulps) do
    a = :erlang.float a
    b = :erlang.float b

    cond do
      signbit(a) != signbit(b)
        -> false
      abs(a - b) <= epsilon
        -> true
      ulp_diff(a, b) <= max_ulps
        -> true
      true
        -> false
    end
  end

  @doc """
  [ULP](https://en.wikipedia.org/wiki/Unit_in_the_last_place) difference.
  """
  @spec ulp_diff(float, float) :: integer
  def ulp_diff(a, b), do: abs(as_uint64(a) - as_uint64(b))

end
