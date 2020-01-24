defmodule Numy.SL do
  @moduledoc """
  NIF wrapper around GSL.
  """

  @on_load :load_nifs

  @doc """
  Callback on module's load. Loads NIF shared library.
  """
  def load_nifs do
    path = :filename.join(:code.priv_dir(:numy), 'libnumy_gsl')
    load_res = :erlang.load_nif(path, 0)
    case load_res do
      :ok ->
        :ok
      {_error, {_reason, err_msg}} ->
        IO.puts "can't load numy_gsl.so: " <> err_msg
        :abort
      {_,e} ->
        IO.inspect e
        :abort
    end

  end

  @doc """
  Create new tensor NIF resource.
  """
  #@spec create_tensor(%Numy.Lapack{}) :: tensor_res
  def create_tensor(_tensor_struct) do
    raise "tensor_create/1 not implemented"
  end
end
