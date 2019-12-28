defmodule Numy.NIF.Lapack do
  @moduledoc """
  todo
  """

  @on_load :load_nifs

  @doc """
  Callback on module's load. Loads NIF shared library.
  """
  def load_nifs do
    mix_app = Mix.Project.config[:app]
    path = :filename.join(:code.priv_dir(mix_app), 'libnumy_lapack')
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
      if "#{nif_numy_version()}" != "#{Mix.Project.config[:version]}" do
        raise "NIF Numy version is #{nif_numy_version()}, " <>
              "expected #{Mix.Project.config[:version]}"
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

  @spec cblas_drotg(float, float) :: {float,float,float,float}
  def cblas_drotg(_a,_b) do
    raise "cblas_drotg/2 not implemented"
  end

  @spec generate_plane_rotation(number, number) :: :error | Keyword.t()
  def generate_plane_rotation(a, b) when is_number(a) and is_number(b) do
    try do
      {r, z, c, s} = cblas_drotg(a/1, b/1)
      [r: r, z: z, c: c, s: s]
    rescue
      _ ->
      :error
    end
  end


end
