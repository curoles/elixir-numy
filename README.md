# Numy

**Numy** is a library to be used for scientific and technical computing.

**Numy** contains modules for:

- Linear Algebra. **Numy** has NIF wrapper around native LAPACK library.
- more not yet

## Table of contents

- [Example](#example)
- [Comparison](#comparison)
- [Installation](#installation)
- [Linear Algebra with LAPACK](#linear-algebra-with-lapack)
  * [BLAS](#blas)

## Example

See this example in LAPACK [reference documentation](http://www.netlib.org/lapack/explore-html/d8/dd5/example___d_g_e_l_s__rowmajor_8c_source.html).


## Comparison

The closest to Numy project (that I am aware of) is Matrex. Matrex is using immutable binaries
and NIF code is calling `enif_make_binary` to return a result (matrix). `enif_make_binary` allocates
memory space for the new binary. Numy on other hand is using mutable NIF resources and can reuse
already allocated memory to store the result inside the context of NIF module.

## Installation

## Linear Algebra with LAPACK

### BLAS

See [Quick Reference Guide to the BLAS](http://www.netlib.org/lapack/lug/node145.html).

#### BLAS Level 1

|          Wrapper function       |       Direct function      |        Description               |
| ------------------------------: | -------------------------: | ---------------------------------|
|         generate_plane_rotation |                 cblas_drotg| |
| | | |

#### BLAS Level 2

#### BLAS Level 3

### LAPACK

<!--
## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `numy` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:numy, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/numy](https://hexdocs.pm/numy).

-->