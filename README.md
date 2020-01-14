# Numy
[![hex.pm version](https://img.shields.io/hexpm/v/numy.svg)](https://hex.pm/packages/numy)
[![Build Status](https://travis-ci.org/curoles/elixir-numy.svg?branch=master)](
https://travis-ci.org/curoles/elixir-numy)
[![Workflow](https://github.com/curoles/elixir-numy/workflows/Elixir%20CI/badge.svg)](
https://github.com/curoles/elixir-numy/actions)
[![hex.pm](https://img.shields.io/hexpm/l/numy.svg)](
https://github.com/curoles/elixir-numy/blob/master/LICENSE)

**Numy** is LAPACK based scientific computing library.
Online API documentation is [here](https://hexdocs.pm/numy/readme.html).

## Table of contents

- [Example](#example)
- [Comparison](#comparison)
- [Installation](#installation)
- [Mutable internal state](#mutable-internal-state)
- [Vector operations](#vector-operations)
- [Set operations](#set-operations)

## Example

See this example in LAPACK [reference documentation](
http://www.netlib.org/lapack/explore-html/d8/dd5/example___d_g_e_l_s__rowmajor_8c_source.html).

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

Ubuntu 18.04, `sudo apt install build-essential liblapacke-dev gfortran`.

The package can be installed
by adding `numy` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:numy, "~> 0.1.4"}
  ]
end
```

## Mutable internal state

For performance reasons, Numy NIF objects are mutable. That is, some API functions
change internal state of an object. Two sets of APIs are provided, one has functions
that change object's internal state and other that does not change it.
In order to maintain that immutability, original input/output object is copied and
it is its copy that gets mutated.

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

## Vector operations

Vector [Jupyter tutorials](
https://github.com/curoles/numy-tutorials/blob/master/README.md):

- [Vector creation and initialization.](
  https://github.com/curoles/numy-tutorials/blob/master/vector/VectorCreate.ipynb)
- [Vector access.](
  https://github.com/curoles/numy-tutorials/blob/master/vector/VectorAccess.ipynb)
- [Vector unary operations.](
  https://github.com/curoles/numy-tutorials/blob/master/vector/VectorUnaryOp.ipynb)
- [Vector binary operations.](
  https://github.com/curoles/numy-tutorials/blob/master/vector/VectorBinaryOp.ipynb)


| Function          |`Vc`|`Vcm`| Description                                            |
| :------------------ |:-:|:-:| :----------------------------------------------------- |
| `new(nelm)`         |   |   | Create new vector of size nelm                         |
| `new(list)`         |   |   | Create new vector from Elixir list                     |
| `new(v)`            |   |   | Create new vector as copy of another vector            |
| `new(v1,v2)`        |   |   | Create new vector as concatenation of 2 other vectors  |
| `save_to_file(v)`   |   |   | Save vectors to a file                                 |
| `load_from_file(fn)`|   |   | Load vecotr from a file                                |
| `assign_zeros(v)`   | x |   | Assign 0.0 to all elements                             |
| `assign_ones(v)`    | x |   | Assign 1.0 to all elements                             |
| `assign_random(v)`  | x |   | Assign random values to the elements                   |
| `assign_all(v,val)` | x |   | Assign certain values to all elements                  |
| `empty?(v)`         | x |   | Return true if vector is empty                         |
| `data(v)`           | x |   | Get data as a list                                     |
| `at(v,pos)`         | x |   | Get value of N-th element                              |
| `set_at!(v,pos,val)`|   | x | Set value of N-th element                              |
| `contains?(v,val)`  | x |   | Check if value exists in the vector                    |
| `find(v,val)`       | x |   | Find value in vector and return its position, -1 if can't find|
| `equal?(v1,v2)`     | x |   | Compare 2 vectors                                      |
| `add(v1,v2)`        | x |   | Add 2 vectors, cᵢ ← aᵢ + bᵢ                            |
| `add!(v1,v2)`       |   | x | aᵢ ← aᵢ + bᵢ                                           |
| `sub(v1,v2)`        | x |   | Subtract one vector from other, cᵢ ← aᵢ - bᵢ           |
| `sub!(v1,v2)`       |   | x | aᵢ ← aᵢ - bᵢ                                           |
| `mul(v1,v2)`        | x |   | Multiply 2 vectors, cᵢ ← aᵢ×bᵢ                         |
| `mul!(v1,v2)`       |   | x | aᵢ ← aᵢ×bᵢ                                             |
| `div(v1,v2)`        | x |   | Divide 2 vectors, cᵢ ← aᵢ÷bᵢ                           |
| `div!(v1,v2)`       |   | x | aᵢ ← aᵢ÷bᵢ                                             |
| `scale(v,factor)`   | x |   | Multiply each element by a constant, aᵢ ← aᵢ×scale_factor |
| `scale!(v,factor)`  |   | x | aᵢ ← aᵢ×scale_factor                                   |
| `offset(v,off)`     | x |   | Add a constant to each element, aᵢ ← aᵢ + offset       |
| `offset!(c,off)`    |   | x | aᵢ ← aᵢ + offset                                       |
| `negate(v)`         | x |   | Change sign of each element, aᵢ ← -aᵢ                  |
| `negate!(v)`        |   | x | aᵢ ← -aᵢ                                               |
| `dot(v1,v2)`        | x |   | Dot product of 2 vectors, ∑aᵢ×bᵢ                       |
| `sum(v)`            | x |   | Sum of all elements, ∑aᵢ                               |
| `average(v)`        | x |   | Average (∑aᵢ)/length                                   |
| `max(v)`            | x |   | Get max value                                          |
| `min(v)`            | x |   | Get min value                                          |
| `max_index(v)`      | x |   | Get index of max value                                 |
| `min_index(v)`      | x |   | Get index of min value                                 |
| `apply_heaviside(v)`| x |   | Step function, aᵢ ← 0 if aᵢ < 0 else 1                 |
| `apply_heaviside!(v)`|  | x |                                                        |
| `apply_sigmoid(v)`  | x |   | f(x) = 1/(1 + e⁻ˣ)                                     |
| `apply_sigmoid!(v)` |   | x |                                                        |
| `sort(v)`           | x |   | Sort elements of array                                 |
| `sort!(v)`          |   | x | Sort elements of array in-place                        |
| `reverse(v)`        | x |   | Reverse order of elements                              |
| `reverse!(v)`       |   | x | Reverse in-place                                       |
| `axpby(v)`          | x |   | cᵢ ← aᵢ×factor_a + bᵢ×factor_b                         |
| `axpby!(v)`         |   | x | aᵢ ← aᵢ×factor_a + bᵢ×factor_b                         |
| `swap_ranges(a,b,n)`|   |   | swap values between 2 vectors                          |


## Set operations

`Numy.Lapack.Vector` implements `Numy.Set` protocol with base Set operations.

> Note: order of elements of input vector can change (they get sorted)
> when `Numy.Set` functions are invoked.

```elixir
iex(6)> a = Numy.Lapack.Vector.new(1..5)
#Vector<size=5, [1.0, 2.0, 3.0, 4.0, 5.0]>
iex(7)> b = Numy.Lapack.Vector.new(5..10)
#Vector<size=6, [5.0, 6.0, 7.0, 8.0, 9.0, 10.0]>
iex(8)> Numy.Set.union(a,b)
#Vector<size=10, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]>
iex(9)> Numy.Set.intersection(a,b)
#Vector<size=1, [5.0]>
iex(10)> Numy.Set.diff(a,b)
#Vector<size=4, [1.0, 2.0, 3.0, 4.0]>
iex(11)> Numy.Set.symm_diff(a,b)
#Vector<size=9, [1.0, 2.0, 3.0, 4.0, 6.0, 7.0, 8.0, 9.0, 10.0]>
```

<!--## Linear Algebra BLAS

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
-->
