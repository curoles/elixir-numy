/**
 * @file
 * @brief     GSL NIF bindings. 
 * @author    Igor Lesik 2019
 * @copyright Igor Lesik 2019
 *
 * @see http://erlang.org/doc/man/erl_nif.html
 *
 * Note: ERL_NIF_TERM is a “wrapper” type that represents all Erlang types
 *       (like binary, list, tuple, and so on) in C.
 *
 */
#include <cstring>

#include <erl_nif.h>

#include "tensor/tensor.hpp"
#include "tensor/nif_resource.hpp"

static ErlNifFunc nif_funcs[] = {
    {       "create_tensor",   1,      numy_tensor_create,   0}
};

// Performs all the magic needed to actually hook things up.
//
ERL_NIF_INIT(
    Elixir.Numy.Sl,  // Erlang module where the NIFs we export will be defined
    nif_funcs,       // array of ErlNifFunc structs that defines which NIFs will be exported
    &numy_load_nif,
    &numy_reload_nif,
    &numy_upgrade_nif,
    &numy_unload_nif
)
