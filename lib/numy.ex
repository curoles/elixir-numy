defmodule Numy do
  @moduledoc false
  #"""
  #Numy is:

  #- NIF wrapper around LAPACK.
  #- Collection of basic operations on vectors and matrices.
  #"""

end

defmodule Numy.Gnuplot do
  def capture(out \\ <<>>) do
    receive do
      {_, {:data, data}} ->
        capture(out <> data)
      {_, :closed} ->
        out
    after
      1_000 ->
        out
    end
  end
end
