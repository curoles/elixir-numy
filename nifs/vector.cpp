/**
 * @file      Typical vector operations.
 * @brief
 * @author    Igor Lesik 2019
 * @copyright Igor Lesik 2019
 *
 */
#include <erl_nif.h>

#define UNUSED __attribute__((unused))
#define NUMY_ERL_FUN static ERL_NIF_TERM

static inline
double dot(const double a[], const double b[], unsigned length)
{
    double result = 0.0;
    for (unsigned int i = 0; i < length; ++i) {
        result += a[i] * b[i];    
    }
    return result;
}

/**
 * Copy Erlang list to C array. 
 * 
 * @return true on success
 */
bool make_vector_from_list(ErlNifEnv* env, ERL_NIF_TERM list, double outVector[], unsigned length) 
{
    double headVal;
    ERL_NIF_TERM head, tail, currentList = list;

    for (unsigned int i = 0; i < length; ++i) 
    {
        if (!enif_get_list_cell(env, currentList, &head, &tail))  {
            return false;
        }
        currentList = tail;
        if (!enif_get_double(env, head, &headVal)) {
            return false;
        }
        outVector[i] = headVal;
    }

    return true;
}

NUMY_ERL_FUN nif_dot_product(ErlNifEnv* env, int /*argc*/, const ERL_NIF_TERM argv[] UNUSED)
{
    unsigned int length = 0, length2 = 0;
    
    if (!enif_get_list_length(env, argv[0], &length)) {
        return enif_make_badarg(env);
    }

    if (!enif_get_list_length(env, argv[1], &length2)) {
        return enif_make_badarg(env);
    }

    if (length2 != length) {
        return enif_make_badarg(env);
    }

    double* vector1 = new double[length];
    double* vector2 = new double[length];

    ERL_NIF_TERM retVal;

    if (!make_vector_from_list(env, argv[0], vector1, length) or
        !make_vector_from_list(env, argv[1], vector2, length))
    {
        retVal = enif_make_badarg(env);
    }
    else {
        retVal = enif_make_double(env, dot(vector1, vector2, length));
    }

    delete[] vector1;
    delete[] vector2;

    return retVal;
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
    //    Erlang function name  arity         function    flags
    {        "nif_dot_product",     2, nif_dot_product,   ERL_NIF_DIRTY_JOB_CPU_BOUND}
};

// Perform all the magic needed to actually hook things up.
//
ERL_NIF_INIT(
    Elixir.Numy.Vector, // Erlang module where the NIFs we export will be defined
    nif_funcs,          // array of ErlNifFunc structs that defines which NIFs will be exported
    &load_nif,
    &reload_nif,
    &upgrade_nif,
    &unload_nif
)