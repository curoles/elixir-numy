# Releases

## 0.1.2 (01/xx/20) basic vector operations

- vector ops protocol `Numy.Vc`
- protocol `Numy.Vcm` for ops that mutate vector state
- module `Numy.Vector` with generic implementation
- experimental module `Numy.BigVector` with Flow, results are bad now
- module `Numy.Lapack.Vector` that implements `Numy.Vc` and `Numy.Vcm`

## 0.1.1 (01/01/20) Fixing 1st release

Fix how .so files are searched

## 0.1.0 (01/01/20) First release

- create NIF module Numy.Lapack, link with generic Netlib LAPACK
- implement Tensor as mutable NIF resource
- define Elixir Struct named `Numy.Lapack` with fields:
  * shape
  * nif_resource
- when NIF Tensor resource is created and returned to Elixir,
  we write it to the field `nif_resource` of the struct.
- implement `assign` and `data` to assign new values to NIF resource
  Tensor and get data back to Elixir as a list.
- wrap C function `lapack_dgels`
- test LLS with the example

```elixir
iex(1)> a = Numy.Lapack.new_tensor([3,5])
#Numy.Lapack<shape: [...], ...>
iex(2)> Numy.Tz.assign(a, [
...(2)> [1,1,1],
...(2)> [2,3,4],
...(2)> [3,5,2],
...(2)> [4,2,5],
...(2)> [5,4,3]])
:ok
iex(3)> b = Numy.Lapack.new_tensor([2,5])
#Numy.Lapack<shape: [...], ...>
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
iex(7)> Numy.Float.close?(solution, [[2,1], [1,1], [1,2]])
true
```