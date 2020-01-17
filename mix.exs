defmodule Mix.Tasks.Compile.Numy do
  @moduledoc """
  Compile native LAPACK wrapper and other C code.

  We will add this "compiler" to the list of compilers
  and mix will call it during `mix compile`.

  See https://hexdocs.pm/mix/1.0.5/Mix.Tasks.Compile.html
  """

  @doc """
  Callback implementation https://hexdocs.pm/mix/1.0.5/Mix.Tasks.Compile.html#run/1
  """
  @spec run(OptionParser.argv) :: :ok | :noop
  def run(_args) do
    {result, _errcode} = System.cmd(
      "make",
      [ "MIX_ENV=#{Mix.env}",
        "NUMY_VERSION=#{Numy.MixProject.project[:version]}"
      ]
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
      version: "0.1.4",
      elixir: "~> 1.9",
      description: "LAPACK based scientific library",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      # Add our native compilation step to the list of compilers,
      # see https://hexdocs.pm/mix/1.0.5/Mix.Tasks.Compile.html
      compilers: [:numy] ++ Mix.compilers,


      # Docs
      name: "Numy",
      source_url: "https://github.com/curoles/elixir-numy",
      homepage_url: "https://github.com/curoles/elixir-numy",
      docs: [
        main: "readme", # The main page in the docs
        #logo: "path/to/logo.png",
        authors: ["Igor Lesik"],
        extras: [
          "README.md", #"RELEASE.md",
          #"nifs/lapack/netlib/README.md": [filename: "nifs_lapack_README"]
        ]
      ]
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
      {:ex_doc,  "~> 0.21", only: :dev, runtime: false},
      {:benchee, "~> 1.0",  only: [:dev, :test]},
      #{:flow, "~> 0.15.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/curoles/elixir-numy"},
      files: [
        "lib",
        "nifs",
        "Makefile",
        "README.md",
        "mix.exs"
      ]
    ]
  end
end
