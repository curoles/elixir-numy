defmodule Numy.NIF.Lapack do
  @moduledoc """
  todo
  """

  @on_load :load_nifs

  mix_app_ = Mix.Project.config[:app]

  @doc """
  Callback on module's load. Loads NIF shared library.
  """
  def load_nifs do
    path = :filename.join(:code.priv_dir(unquote(mix_app_)), 'libnumy')
    :erlang.load_nif(path, 0)
  end

  @doc """
  Get string with Elixir Numy version at the moment of NIF compilation.
  Use it for sanity check.

  ## Examples

      iex> Numy.NIF.Lapack.numy_version
      '0.1.0'
  """
  @spec numy_version() :: String.t
  def numy_version() do
    raise "NIF numy_version/0 not implemented"
  end
end
