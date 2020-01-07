/**
 * @file
 * @brief     Typical vector operations.
 * @author    Igor Lesik 2019
 * @copyright Igor Lesik 2019
 *
 */
#pragma once

#include <erl_nif.h>

ERL_NIF_TERM numy_vector_at         (ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM numy_vector_equal      (ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM numy_vector_add        (ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM numy_vector_sub        (ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM numy_vector_mul        (ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM numy_vector_div        (ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM numy_vector_dot_product(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);