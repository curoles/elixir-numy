/**
 * @file
 * @brief     Tensor is a multi-dimentional matrix (sometimes caled ND-Array)
 *            contaning elements of a single data type.
 * @author    Igor Lesik 2019
 * @copyright Igor Lesik 2019
 *
 */
//#include <cstdio>
//#include <cassert>
#include <erl_nif.h>

#include "tensor.hpp"

#define UNUSED __attribute__((unused))

namespace numy::tnsr {

/**
 * NIFResource manages Tensor NIF resources. 
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
    void dtor(ErlNifEnv* env, void* obj)
    {
        numy::Tensor* tensor = (numy::Tensor*) obj;
        //assert(tensor->magic == numy::Tensor::MAGIC);
        if (tensor->magic != numy::Tensor::MAGIC) {
            enif_raise_exception(env,
                enif_make_string(env, "Tensor bad magic", ERL_NIF_LATIN1));
        }
        else {
            if (tensor->data != nullptr) {
                enif_free(tensor->data);
            }
        }
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

static
bool tensor_construct(numy::Tensor* tensor,
    ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    // Initialize fields
    tensor->magic  = numy::Tensor::MAGIC;
    tensor->nrDims = 0;
    tensor->data   = nullptr;

    if (argc != 1) { return false; }

    ERL_NIF_TERM map = argv[0];

    if (!enif_is_map(env, map)) { return false; }

    size_t mapSize = 0;
    if (!enif_get_map_size(env, map, &mapSize)) { return false; }

    if (mapSize == 0) { return false; }

    ERL_NIF_TERM atomShape;
    if (!enif_make_existing_atom(env, "shape", &atomShape, ERL_NIF_LATIN1)) { return false; }

    ERL_NIF_TERM termShape;
    if (!enif_get_map_value(env, map, atomShape, &termShape)) { return false; }

    if (!enif_is_list(env, termShape)) { return false; }

    unsigned lenShape = 0;
    if (!enif_get_list_length(env, termShape, &lenShape)) { return false; }

    if (lenShape == 0) { return false; }

    tensor->nrElements = 1;

    int headVal;
    ERL_NIF_TERM head, tail, currentList = termShape;

    for (unsigned int i = 0; i < lenShape; ++i) 
    {
        if (!enif_get_list_cell(env, currentList, &head, &tail))  {
            return false;
        }
        currentList = tail;
        if (!enif_get_int(env, head, &headVal)) {
            return false;
        }
        if (headVal == 0 or headVal < 0) {
            return false;
        }
        tensor->shape[i] = headVal;
        tensor->nrElements *= tensor->shape[i];
    }

    tensor->nrDims = lenShape;

    unsigned sizeOfDataType = sizeof(double);
    tensor->dataSize = tensor->nrElements * sizeOfDataType;
    tensor->data = enif_alloc(tensor->dataSize);

    return true;
}

static ERL_NIF_TERM
tensor_create(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
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

    if (!tensor_construct(tensor, env, argc, argv)) {
        // enif_fprintf(stderr, "failed to construct Tensor\n");
        return enif_make_badarg(env);
    }

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
    {           "create", 1,              tensor_create, 0/*ERL_NIF_DIRTY_JOB_CPU_BOUND*/},
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