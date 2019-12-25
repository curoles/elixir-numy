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
 */
#include <erl_nif.h>

#define UNUSED __attribute__((unused))
#define NUMY_ERL_FUN static ERL_NIF_TERM

#define STR(x) #x
#define XSTR(x) STR(x)

NUMY_ERL_FUN numy_version(ErlNifEnv* env, int /*argc*/, const ERL_NIF_TERM argv[] UNUSED)
{
    return enif_make_string(env, XSTR(NUMY_VERSION), ERL_NIF_LATIN1);
}

static ErlNifFunc nif_funcs[] = {
    // Erlang function name  arity      function   flags
    {        "numy_version",     0, numy_version,    0}
};

// Performs all the magic needed to actually hook things up.
//
ERL_NIF_INIT(
    Elixir.Numy.NIF.Lapack, // Erlang module where the NIFs we export will be defined
    nif_funcs,       // array of ErlNifFunc structs that defines which NIFs will be exported
    nullptr,         // load
    nullptr,         // upgrade
    nullptr,         // unload
    nullptr          // reload
)