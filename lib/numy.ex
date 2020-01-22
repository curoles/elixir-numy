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

defmodule Numy.Tools do

  @doc """
  Perform a parallel map by calling the function against each element
  in a new process.
  """
  def pmap(collection, func) do
    collection
    |> Enum.map(&(Task.async(fn -> func.(&1) end)))
    |> Enum.map(&Task.await/1)
  end
  # defp pmap(collection, function) do
  #   me = self
  #
  #   collection
  #   |> Enum.map(fn (elem) ->
  #     spawn_link fn -> (send me, { self, function.(elem) }) end
  #   end)
  #   |> Enum.map(fn (pid) ->
  #     receive do { ^pid, result } -> result end
  #   end)
  # end

end
