/**
 * @file
 * @brief     Typical vector operations.
 * @author    Igor Lesik 2019
 * @copyright Igor Lesik 2019
 *
 */
#pragma once

#include <erl_nif.h>

#define DECL_NIF(fun) ERL_NIF_TERM fun (ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

DECL_NIF(numy_vector_get_at)
DECL_NIF(numy_vector_set_at)
DECL_NIF(numy_vector_assign_all)
DECL_NIF(numy_vector_equal)
DECL_NIF(numy_vector_add)
DECL_NIF(numy_vector_sub)
DECL_NIF(numy_vector_mul)
DECL_NIF(numy_vector_div)
DECL_NIF(numy_vector_scale)
DECL_NIF(numy_vector_offset)
DECL_NIF(numy_vector_dot)
DECL_NIF(numy_vector_sum)
DECL_NIF(numy_vector_max)
DECL_NIF(numy_vector_min)
DECL_NIF(numy_vector_max_index)
DECL_NIF(numy_vector_min_index)
DECL_NIF(numy_vector_heaviside)
DECL_NIF(numy_vector_sigmoid)
DECL_NIF(numy_vector_sort)
DECL_NIF(numy_vector_reverse)
DECL_NIF(numy_vector_axpby)

#undef DECL_NIF