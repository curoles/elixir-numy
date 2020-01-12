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
#include <cstring>

#include <erl_nif.h>
#include <lapacke.h>
#include <cblas.h> 

#include "tensor/tensor.hpp"
#include "tensor/nif_resource.hpp"
#include "tensor/vector.hpp"
#include "lapack/netlib/blas.hpp"

#define UNUSED __attribute__((unused))
#define NUMY_ERL_FUN static ERL_NIF_TERM

#define STR_(x) #x
#define STR(x) STR_(x)

/**
 * load is called when the NIF library is loaded and no previously loaded
 * library exists for this module.
 */
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

    tensor->dtype = numy::Tensor::T_DBL;
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

NUMY_ERL_FUN nif_numy_version(ErlNifEnv* env, int /*argc*/, const ERL_NIF_TERM argv[] UNUSED)
{
    return enif_make_string(env, STR(NUMY_VERSION), ERL_NIF_LATIN1);
}

NUMY_ERL_FUN tensor_fill(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 2) {
        return enif_make_badarg(env);
    }

    double fillVal{0.0};
    if (!enif_get_double(env, argv[1], &fillVal)) {
        int64_t intFillVal{0};
        if (!enif_get_int64(env, argv[1], &intFillVal)) {
            return enif_make_badarg(env);
        }
        fillVal = intFillVal;
    }

    const numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or tensor->magic != numy::Tensor::MAGIC) {
	    return enif_make_badarg(env);
    }

    double* data = (double*) tensor->data;

    for (unsigned i = 0; i < tensor->nrElements; ++i) {
        data[i] = fillVal;
    }

    return numy::tnsr::getOkAtom(env);
}

NUMY_ERL_FUN tensor_data(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 2) {
        return enif_make_badarg(env);
    }

    int maxNrElm{0};
    if (!enif_get_int(env, argv[1], &maxNrElm)) {
        return enif_make_badarg(env);
    }

    const numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or tensor->magic != numy::Tensor::MAGIC or !tensor->isValid()) {
	    return enif_make_badarg(env);
    }

    if (tensor->nrElements == 0) {
        return enif_make_list(env, 0);
    }

    unsigned retNrElm = (maxNrElm < 1)?
        tensor->nrElements:
        std::min(tensor->nrElements, (unsigned)maxNrElm);

    double* data = (double*) tensor->data;

    ERL_NIF_TERM list, el;
    list = enif_make_list(env, 0);

    for (int i = retNrElm - 1; i >= 0; --i) {
        el = enif_make_double(env, data[i]);
        list = enif_make_list_cell(env, el, list);
    }

    return list;
}

NUMY_ERL_FUN tensor_assign(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 2) {
        return enif_make_badarg(env);
    }

    const numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or tensor->magic != numy::Tensor::MAGIC) {
	    return enif_make_badarg(env);
    }

    ERL_NIF_TERM list = argv[1];
    if (!enif_is_list(env, list)) {
        return enif_make_badarg(env);
    }

    unsigned listLen{0};
    if (!enif_get_list_length(env, list, &listLen)) {
        return enif_make_badarg(env);
    }

    unsigned len = std::min(listLen, tensor->nrElements);

    double* data = (double*) tensor->data;

    double headVal; int64_t headIntVal;
    ERL_NIF_TERM head, tail, currentList = list;

    for (unsigned i = 0; i < len; ++i)
    {
        if (!enif_get_list_cell(env, currentList, &head, &tail))  {
            break;
        }
        currentList = tail;
        if (!enif_get_double(env, head, &headVal)) {
            if (!enif_get_int64(env, head, &headIntVal)) {
                break;
            }
            headVal = headIntVal;
        }
        data[i] = headVal;
    }

    return numy::tnsr::getOkAtom(env);
}

NUMY_ERL_FUN data_copy_all(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 2) {
        return enif_make_badarg(env);
    }

    const numy::Tensor* tensor_dst = numy::tnsr::getTensor(env, argv[0]);
    const numy::Tensor* tensor_src = numy::tnsr::getTensor(env, argv[1]);

    if (tensor_dst == nullptr or tensor_dst->magic != numy::Tensor::MAGIC or
        tensor_src == nullptr or tensor_src->magic != numy::Tensor::MAGIC)
    {
	    return enif_make_badarg(env);
    }

    unsigned size = std::min(tensor_dst->dataSize, tensor_src->dataSize);

    std::memcpy(tensor_dst->data, tensor_src->data, size);

    return enif_make_int(env, size);
}

NUMY_ERL_FUN tensor_nrelm(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 1) {
        return enif_make_badarg(env);
    }

    const numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or !tensor->isValid()) {
	    return enif_make_badarg(env);
    }

    return enif_make_uint(env, tensor->nrElements);
}

//http://www.netlib.org/lapack/explore-html/d7/d3b/group__double_g_esolve_ga225c8efde208eaf246882df48e590eac.html#ga225c8efde208eaf246882df48e590eac
NUMY_ERL_FUN numy_lapack_dgels(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 2) {
        return enif_make_badarg(env);
    }

    const numy::Tensor* tensorA = numy::tnsr::getTensor(env, argv[0]);
    const numy::Tensor* tensorB = numy::tnsr::getTensor(env, argv[1]);

    if (tensorA == nullptr or tensorA->magic != numy::Tensor::MAGIC or !tensorA->isValid() or
        tensorB == nullptr or tensorB->magic != numy::Tensor::MAGIC or !tensorB->isValid())
    {
	    return enif_make_badarg(env);
    }

    double* a = (double*) tensorA->data;
    double* b = (double*) tensorB->data;

    int aNrRows = tensorA->nr_rows();
    int aNrCols = tensorA->nr_cols();
    int nrhs    = tensorB->nr_cols();
    int lda     = aNrCols;
    int ldb     = nrhs;

    lapack_int res = LAPACKE_dgels(
        LAPACK_ROW_MAJOR,  // matrix_layout
        'N',      // trans: 'N' => A, 'T' => A^T
        aNrRows,  // M - The number of rows of the matrix A
        aNrCols,  // N - The number of columns of the matrix A
        nrhs,     // the number of columns of the matrices B and X
        a,        // On entry, the M-by-N matrix A. On exit, details of its QR/LQ factorization
        lda,      // The leading dimension of the array A.  LDA >= max(1,M).
        b,        // B is M-by-NRHS. On exit, solution X.
        ldb       // The leading dimension of the array B. LDB >= MAX(1,M,N).
    );

    return enif_make_int(env, res);
}

static ErlNifFunc nif_funcs[] = {
    {       "create_tensor",   1,           tensor_create,   0},
    {        "tensor_nrelm",   1,            tensor_nrelm,   0},
    {    "nif_numy_version",   0,        nif_numy_version,   0},
    {         "fill_tensor",   2,             tensor_fill,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {         "tensor_data",   2,             tensor_data,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {       "tensor_assign",   2,           tensor_assign,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {       "data_copy_all",   2,           data_copy_all,   0},
    { "tensor_save_to_file",   2,numy_tensor_save_to_file,   ERL_NIF_DIRTY_JOB_IO_BOUND},
    {"tensor_load_from_file",  1,numy_tensor_load_from_file, ERL_NIF_DIRTY_JOB_IO_BOUND},
    {          "blas_drotg",   2,         numy_blas_drotg,   0},
    {          "blas_dcopy",   5,         numy_blas_dcopy,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {        "lapack_dgels",   2,       numy_lapack_dgels,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {          "vector_add",   2,         numy_vector_add,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {          "vector_sub",   2,         numy_vector_sub,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {          "vector_mul",   2,         numy_vector_mul,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {          "vector_div",   2,         numy_vector_div,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {          "vector_dot",   2,         numy_vector_dot,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {       "vector_get_at",   2,      numy_vector_get_at,   0},
    {       "vector_set_at",   3,      numy_vector_set_at,   0},
    {   "vector_assign_all",   2,  numy_vector_assign_all,   0},
    {        "vector_equal",   2,       numy_vector_equal,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {        "vector_scale",   2,       numy_vector_scale,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {       "vector_offset",   2,      numy_vector_offset,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {       "vector_negate",   1,      numy_vector_negate,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {          "vector_dot",   2,         numy_vector_dot,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {          "vector_sum",   1,         numy_vector_sum,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {          "vector_max",   1,         numy_vector_max,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {          "vector_min",   1,         numy_vector_min,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {    "vector_max_index",   1,   numy_vector_max_index,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {    "vector_min_index",   1,   numy_vector_min_index,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {    "vector_heaviside",   2,   numy_vector_heaviside,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {      "vector_sigmoid",   1,     numy_vector_sigmoid,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {         "vector_sort",   1,        numy_vector_sort,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {      "vector_reverse",   1,     numy_vector_reverse,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {        "vector_axpby",   4,       numy_vector_axpby,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {   "vector_copy_range",   7,  numy_vector_copy_range,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {  "vector_swap_ranges",   5, numy_vector_swap_ranges,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {         "vector_find",   2,        numy_vector_find,   ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {              "set_op",   3,             numy_set_op,   ERL_NIF_DIRTY_JOB_CPU_BOUND}
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
