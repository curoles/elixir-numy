/**
 * @file
 * @brief     NIF load/unload functions.
 * @author    Igor Lesik 2020
 * @copyright Igor Lesik 2020
 *
 */
#include <cstring>

#include <erl_nif.h>


#include "tensor/tensor.hpp"
#include "tensor/nif_resource.hpp"

int numy_load_nif(ErlNifEnv* env, void** priv, ERL_NIF_TERM /*info*/)
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

int numy_reload_nif(ErlNifEnv* /*env*/, void** /*priv*/, ERL_NIF_TERM /*info*/)
{
    return 0; // OK
}

/**
 * upgrade is called when the NIF library is loaded
 * and there is old code of this module with a loaded NIF library.
 */
int numy_upgrade_nif(ErlNifEnv* env, void** priv, void** old_priv, ERL_NIF_TERM info)
{
    if (old_priv != nullptr and *old_priv != nullptr) {
        enif_free(priv);//XXX ??? old_priv
    }

    return load_nif(env, priv, info);

}

void numy_unload_nif(ErlNifEnv* /*env*/, void* priv)
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

ERL_NIF_TERM numy_tensor_create(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
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
