# Numy
[![hex.pm version](https://img.shields.io/hexpm/v/numy.svg)](https://hex.pm/packages/numy)
[![Build Status](https://travis-ci.org/curoles/elixir-numy.svg?branch=master)](
https://travis-ci.org/curoles/elixir-numy)
[![Workflow](https://github.com/curoles/elixir-numy/workflows/Elixir%20CI/badge.svg)](
https://github.com/curoles/elixir-numy/actions)
[![hex.pm](https://img.shields.io/hexpm/l/numy.svg)](
https://github.com/curoles/elixir-numy/blob/master/LICENSE)

**Numy** is LAPACK based scientific computing library.

## Table of contents

- [Example](#example)
- [Comparison](#comparison)
- [Installation](#installation)
- [Mutable internal state](#mutable-internal-state)
- [Linear Algebra with LAPACK](#linear-algebra-with-lapack)
  * [BLAS](#blas)
  * [LAPACK](#lapack)

## Example

See this example in LAPACK [reference documentation](http://www.netlib.org/lapack/explore-html/d8/dd5/example___d_g_e_l_s__rowmajor_8c_source.html).

```elixir
iex(1)> a = Numy.Lapack.new_tensor([3,5])
iex(2)> Numy.Tz.assign(a, [
...(2)> [1,1,1],
...(2)> [2,3,4],
...(2)> [3,5,2],
...(2)> [4,2,5],
...(2)> [5,4,3]])
:ok
iex(3)> b = Numy.Lapack.new_tensor([2,5])
iex(4)> Numy.Tz.assign(b, [
...(4)> [-10,-3],
...(4)> [12,14],
...(4)> [14,12],
...(4)> [16,16],
...(4)> [18,16]])
:ok
iex(5)> Numy.Lapack.solve_lls(a,b)
0
iex(6)> solution = Numy.Lapack.data(b,2*3)
[1.9999999999999982, 0.9999999999999983, 0.9999999999999991, 0.9999999999999997,
 1.0000000000000024, 2.0000000000000018]
iex(7)> Numy.Float.equal?(solution, [[2,1], [1,1], [1,2]])
true
```

## Comparison

The closest to Numy project (that I am aware of) is Matrex. Matrex is using immutable binaries
and NIF code is calling `enif_make_binary` to return a result (matrix). `enif_make_binary` allocates
memory space for the new binary. Numy on other hand is using mutable NIF resources and can reuse
already allocated memory to store the result inside the context of NIF module.

## Installation

Ubuntu 18.04, `sudo apt install liblapacke-dev gfortran`.

The package can be installed
by adding `numy` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:numy, "~> 0.1.2"}
  ]
end
```

## Mutable internal state

For performance reasons, Numy NIF objects are mutable. That is, some API functions
change internal state of an object. Two sets of APIs are provided, one has functions
that change object's internal state and other that does not change it.
In order to maintain that immutability, input/output object is copied and
its copy is mutated.

### Example of immutable addition of two vectors

```elixir
iex(1)> v = Numy.Lapack.Vector.new([1,2,3])
iex(2)> Numy.Vc.add(v,v) # Vc API functions do not mutate internal state
iex(3)> Numy.Vc.data(v)
[1.0, 2.0, 3.0]
```

### Example of two vector addition when one of the vectors changes its state

```elixir
iex(1)> v = Numy.Lapack.Vector.new([1,2,3])
iex(4)> Numy.Vcm.add!(v,v) # Vcm is API that mutates internal state, functions have suffix '!'
iex(5)> Numy.Vc.data(v)
[2.0, 4.0, 6.0]
```

## Linear Algebra BLAS

See [Quick Reference Guide to the BLAS](http://www.netlib.org/lapack/lug/node145.html).

### BLAS Level 1, functions that operate on vectors

|          Wrapper function       |       Direct function      |        Description               |
| ------------------------------: | -------------------------: | ---------------------------------|
|         generate_plane_rotation |                 blas_drotg | |
| | | |

### BLAS Level 2, matrix-vector operations

### BLAS Level 3, matrix-matri operations

## Linear Algebra LAPACK

|          Wrapper function       |       Direct function      |        Description                  |
| ------------------------------: | -------------------------: |-------------------------------------|
|                       solve_lls |               lapack_dgels | Linear Least Squares by QR/LR       |
| | | |

