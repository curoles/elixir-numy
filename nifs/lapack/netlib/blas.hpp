/**
 * @file
 * @brief     BLAS functions
 * @author    Igor Lesik 2019
 * @copyright Igor Lesik 2019
 *
 */
#pragma once

#include <erl_nif.h>

ERL_NIF_TERM numy_blas_drotg(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM numy_blas_dcopy(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);