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
#include <cblas.h> 

#include "tensor/tensor.hpp"

#define UNUSED __attribute__((unused))
#define NUMY_ERL_FUN static ERL_NIF_TERM

#define STR_(x) #x
#define STR(x) STR_(x)

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
    ERL_NIF_TERM ok_atom_;

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
    ok_atom_ = enif_make_atom(env, "ok");

    res_type_ = enif_open_resource_type(
        env,
        "Elixir.Numy.Tensor",
        "resource type Tensor",
        this->dtor,
        (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER),
        nullptr //ErlNifResourceFlags* tried
    );

    return res_type_;
}

/**
 * load is called when the NIF library is loaded and no previously loaded
 * library exists for this module.
 */
static int
load_nif(ErlNifEnv* env, void** priv, ERL_NIF_TERM /*info*/)
{
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

/**
 * upgrade is called when the NIF library is loaded
 * and there is old code of this module with a loaded NIF library.
 */
static int
upgrade_nif(ErlNifEnv* env, void** priv, void** old_priv, ERL_NIF_TERM info)
{
    if (old_priv != nullptr and *old_priv != nullptr) {
        enif_free(priv);
    }

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
    NIFResource* resourceMngr = (NIFResource*) enif_priv_data(env);
    return resourceMngr->get(env, nifTensor);
}

static inline ERL_NIF_TERM getOkAtom(ErlNifEnv* env) {
    return ((NIFResource*) enif_priv_data(env))->ok_atom_;
}

NUMY_ERL_FUN nif_numy_version(ErlNifEnv* env, int /*argc*/, const ERL_NIF_TERM argv[] UNUSED)
{
    return enif_make_string(env, STR(NUMY_VERSION), ERL_NIF_LATIN1);
}

//https://en.wikipedia.org/wiki/Givens_rotation
//http://www.netlib.org/lapack/explore-html/df/d28/group__single__blas__level1_ga2f65d66137ddaeb7ae93fcc4902de3fc.html#ga2f65d66137ddaeb7ae93fcc4902de3fc
NUMY_ERL_FUN numy_blas_drotg(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[] UNUSED)
{
    double a,b,c,s;
    if (argc != 2 or !enif_get_double(env, argv[0], &a) or !enif_get_double(env, argv[1], &b)) {
        return enif_make_badarg(env);
    }

    cblas_drotg(&a, &b, &c, &s);

    return enif_make_tuple4(env,
        enif_make_double(env, a), enif_make_double(env, b),
        enif_make_double(env, c), enif_make_double(env, s));
}

//http://www.netlib.org/lapack/explore-html/df/d28/group__single__blas__level1_ga24785e467bd921df5a2b7300da57c469.html#ga24785e467bd921df5a2b7300da57c469
//DCOPY copies a vector, x, to a vector, y.
// [in]  num    - number of elements in input vector(s)
// [in]  src    - src vector, dimension ( 1 + ( N - 1 )*abs( INCX ) )
// [in]  srcInc - storage spacing between elements src
// [out] dst    - dst vector, dimension ( 1 + ( N - 1 )*abs( INCY ) )
// [in]  dstInc - storage spacing between elements dst
//
NUMY_ERL_FUN numy_blas_dcopy(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[] UNUSED)
{
    if (argc != 5) {
        return enif_make_badarg(env);
    }

    return getOkAtom(env);
}

NUMY_ERL_FUN tensor_fill(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 2) {
        return enif_make_badarg(env);
    }

    double fillVal{0.0};
    if (!enif_get_double(env, argv[1], &fillVal)) {
        int intFillVal{0};
        if (!enif_get_int(env, argv[1], &intFillVal)) {
            return enif_make_badarg(env);
        }
        fillVal = intFillVal;
    }

    const numy::Tensor* tensor = getTensor(env, argv[0]);

    if (tensor == nullptr or tensor->magic != numy::Tensor::MAGIC) {
	    return enif_make_badarg(env);
    }

    double* data = (double*) tensor->data;

    for (unsigned i = 0; i < tensor->nrElements; ++i) {
        data[i] = fillVal;
    }

    return getOkAtom(env);
}

NUMY_ERL_FUN tensor_data(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 1) {
        return enif_make_badarg(env);
    }

    const numy::Tensor* tensor = getTensor(env, argv[0]);

    if (tensor == nullptr or tensor->magic != numy::Tensor::MAGIC) {
	    return enif_make_badarg(env);
    }

    if (tensor->nrElements == 0) {
        return enif_make_list(env, 0);
    }

    double* data = (double*) tensor->data;
    ERL_NIF_TERM* termArr = new ERL_NIF_TERM[tensor->nrElements];

    for (unsigned i = 0; i < tensor->nrElements; ++i) {
        termArr[i] = enif_make_double(env, data[i]);
    }

    ERL_NIF_TERM list = enif_make_list_from_array(env, termArr, tensor->nrElements);

    delete[] termArr;

    return list;
}

static ErlNifFunc nif_funcs[] = {
    {       "create_tensor",     1,    tensor_create,   0},
    {    "nif_numy_version",     0, nif_numy_version,   0},
    {         "fill_tensor",     2,      tensor_fill,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {         "tensor_data",     1,      tensor_data,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {          "blas_drotg",     2,  numy_blas_drotg,   0},
    {          "blas_dcopy",     5,  numy_blas_dcopy,   ERL_NIF_DIRTY_JOB_CPU_BOUND}
};

// Performs all the magic needed to actually hook things up.
//
ERL_NIF_INIT(
    Elixir.Numy.Lapack, // Erlang module where the NIFs we export will be defined
    nif_funcs,       // array of ErlNifFunc structs that defines which NIFs will be exported
    &load_nif,
    &reload_nif,
    &upgrade_nif,
    &unload_nif
)
