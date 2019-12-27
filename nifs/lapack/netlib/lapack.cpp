/**
 * @file
 * @brief
 * @author    Igor Lesik 2019
 * @copyright Igor Lesik 2019
 *
 * @see http://erlang.org/doc/man/erl_nif.html
 *
 * Note: ERL_NIF_TERM is a “wrapper” type that represents all Erlang types
 *       (like binary, list, tuple, and so on) in C.
 *
 * To get LAPACK headers:
 *
 * - Ubuntu: sudo apt install liblapacke-dev
 */
#include <erl_nif.h>
#include <lapacke.h>

#define UNUSED __attribute__((unused))
#define NUMY_ERL_FUN static ERL_NIF_TERM

#define STR(x) #x
#define XSTR(x) STR(x)

NUMY_ERL_FUN nif_numy_version(ErlNifEnv* env, int /*argc*/, const ERL_NIF_TERM argv[] UNUSED)
{
    return enif_make_string(env, XSTR(NUMY_VERSION), ERL_NIF_LATIN1);
}

static int
load_nif(ErlNifEnv* /*env*/, void** /*priv*/, ERL_NIF_TERM /*info*/) {
    return 0; // OK
}

static int
reload_nif(ErlNifEnv* /*env*/, void** /*priv*/, ERL_NIF_TERM /*info*/) {
    return 0; // OK
}

static int
upgrade_nif(ErlNifEnv* env, void** priv, void** /*old_priv*/, ERL_NIF_TERM info) {
    return load_nif(env, priv, info);
}

static void
unload_nif(ErlNifEnv* /*env*/, void* /*priv*/) {
    //
}

static ErlNifFunc nif_funcs[] = {
    // Erlang function name  arity          function    flags
    {    "nif_numy_version",     0, nif_numy_version,   ERL_NIF_DIRTY_JOB_CPU_BOUND}
};

// Performs all the magic needed to actually hook things up.
//
ERL_NIF_INIT(
    Elixir.Numy.NIF.Lapack, // Erlang module where the NIFs we export will be defined
    nif_funcs,       // array of ErlNifFunc structs that defines which NIFs will be exported
    &load_nif,
    &reload_nif,
    &upgrade_nif,
    &unload_nif
)
