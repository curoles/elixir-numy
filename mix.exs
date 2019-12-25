defmodule Mix.Tasks.Compile.Numy do
  @moduledoc """
  Compile native LAPACK wrapper and other C code.

  We will add this "compiler" to the list of compilers
  and mix will call it during `mix compile`.

  See https://hexdocs.pm/mix/1.0.5/Mix.Tasks.Compile.html
  """
  def run(_args) do
    {result, _errcode} = System.cmd(
      "make",
      []
      #stdout_to_stderr: true
    )
    IO.binwrite(result)
  end
end

defmodule Numy.MixProject do
  use Mix.Project

  def project do
    [
      app: :numy,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Add our native compilation step to the list
      # See https://hexdocs.pm/mix/1.0.5/Mix.Tasks.Compile.html
      compilers: [:numy] ++ Mix.compilers
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

end
