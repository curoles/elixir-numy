/**
 * @file
 * @brief     Tensor is a multi-dimentional matrix (sometimes caled ND-Array)
 *            contaning elements of a single data type.
 * @author    Igor Lesik 2019
 * @copyright Igor Lesik 2019
 *
 */
#include <erl_nif.h>

#include "tensor.hpp"

#define UNUSED __attribute__((unused))

namespace numy::tnsr {

/**
 * NIFResource manages Tensor NIF resorces. 
 */
class NIFResource
{
public:
    using ResType = ErlNifResourceType*;

private:
    ResType res_type_ = nullptr;

public:
    ResType open(ErlNifEnv* env);

    static
    void dtor(ErlNifEnv* /*env*/, void* /*obj*/)
    {

    }

    numy::Tensor* allocate() {
        return static_cast<numy::Tensor*>(
            enif_alloc_resource(res_type_, sizeof(numy::Tensor)));
    }

    numy::Tensor* get(ErlNifEnv* env, const ERL_NIF_TERM tensorNifTerm) {
        numy::Tensor* tensor{nullptr};
        return (enif_get_resource(env, tensorNifTerm, res_type_, (void**) &tensor))?
            tensor:
            nullptr;
    }
};

/**
 * 
 * 
 * Notice that enif_open_resource_type is only allowed to be called
 * in the two callbacks `load` and `upgrade`.
 */
NIFResource::ResType NIFResource::open(ErlNifEnv* env)
{
    res_type_ = enif_open_resource_type(
        env,
        "Elixir.Numy.Tensor",
        "resource type Tensor",
        this->dtor,
        ERL_NIF_RT_CREATE,
        nullptr //ErlNifResourceFlags* tried
    );

    return res_type_;
}

} // namespace numy::tnsr


static int
load_nif(ErlNifEnv* env, void** priv, ERL_NIF_TERM /*info*/)
{
    using namespace numy::tnsr;

    NIFResource* resource = (NIFResource*) enif_alloc(sizeof(NIFResource));

    if (resource->open(env) == nullptr) {
        enif_free(resource);
        *priv = nullptr;
        return -1;
    }

    *priv = (void*)resource;

    return 0; // OK
}

static int
reload_nif(ErlNifEnv* /*env*/, void** /*priv*/, ERL_NIF_TERM /*info*/)
{
    return 0; // OK
}

static int
upgrade_nif(ErlNifEnv* env, void** priv, void** /*old_priv*/, ERL_NIF_TERM info)
{
    return load_nif(env, priv, info);
}

static void
unload_nif(ErlNifEnv* /*env*/, void* priv)
{
    if (priv != nullptr) {
        enif_free(priv);
    }
}

static ERL_NIF_TERM
tensor_create(ErlNifEnv* env, int /*argc*/, const ERL_NIF_TERM argv[] UNUSED)
{
    using namespace numy::tnsr;

    NIFResource* resourceMngr = (NIFResource*) enif_priv_data(env);

    if (resourceMngr == nullptr)
        return enif_make_badarg(env);

    numy::Tensor* tensor = resourceMngr->allocate();

    if (tensor == nullptr)
        return enif_make_badarg(env);

    ERL_NIF_TERM nifTensor = enif_make_resource(env, tensor);

    enif_release_resource(tensor);

    return nifTensor;
}

static inline
numy::Tensor* getTensor(ErlNifEnv* env, const ERL_NIF_TERM nifTensor) {
    numy::tnsr::NIFResource* resourceMngr = (numy::tnsr::NIFResource*) enif_priv_data(env);
    return resourceMngr->get(env, nifTensor);
}

static ERL_NIF_TERM
tensor_get_nr_dimensions(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 1) {
        return enif_make_badarg(env);
    }

    const numy::Tensor* tensor = getTensor(env, argv[0]);

    if (tensor == nullptr) {
	    return enif_make_badarg(env);
    }

    return enif_make_int(env, tensor->nrDims);
}

static ErlNifFunc nif_funcs[] = {
    {           "create", 0,              tensor_create, 0/*ERL_NIF_DIRTY_JOB_CPU_BOUND*/},
    {    "nr_dimensions", 1,   tensor_get_nr_dimensions, 0}
};

// Perform all the magic needed to actually hook things up.
//
ERL_NIF_INIT(
    Elixir.Numy.Tensor, // Erlang module where the NIFs we export will be defined
    nif_funcs,          // array of ErlNifFunc structs that defines which NIFs will be exported
    &load_nif,
    &reload_nif,
    &upgrade_nif,
    &unload_nif
)