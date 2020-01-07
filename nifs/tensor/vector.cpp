/**
 * @file
 * @brief     Typical vector operations.
 * @author    Igor Lesik 2019
 * @copyright Igor Lesik 2019
 *
 */
#include <algorithm>

#include <erl_nif.h>

#include "tensor/tensor.hpp"
#include "tensor/nif_resource.hpp"

#include "float_almost_equals.hpp"

#define UNUSED __attribute__((unused))

static inline
double dot_vectors(const double a[], const double b[], unsigned length)
{
    double result = 0.0;
    for (unsigned int i = 0; i < length; ++i) {
        result += a[i] * b[i];
    }
    return result;
}

static inline
void add_vectors(double a[], const double b[], unsigned length)
{
    #pragma GCC ivdep
    for (unsigned int i = 0; i < length; ++i) {
        a[i] += b[i];
    }
}

static inline
void sub_vectors(double a[], const double b[], unsigned length)
{
    #pragma GCC ivdep
    for (unsigned int i = 0; i < length; ++i) {
        a[i] -= b[i];
    }
}

static inline
void mul_vectors(double a[], const double b[], unsigned length)
{
    #pragma GCC ivdep
    for (unsigned int i = 0; i < length; ++i) {
        a[i] *= b[i];
    }
}

static inline
void div_vectors(double a[], const double b[], unsigned length)
{
    #pragma GCC ivdep
    for (unsigned int i = 0; i < length; ++i) {
        a[i] += b[i];
    }
}

static inline
bool vectors_equal(double a[], const double b[], unsigned length)
{
    for (unsigned int i = 0; i < length; ++i) {
        if (!AlmostEquals(a[i], b[i])) return false;
    }

    return true;
}

/**
 * Copy Erlang list to C array. 
 * 
 * @return true on success
 */
bool make_carray_from_list(ErlNifEnv* env, ERL_NIF_TERM list, double outVector[], unsigned length)
{
    double headVal;
    int intVal;
    ERL_NIF_TERM head, tail, currentList = list;

    for (unsigned int i = 0; i < length; ++i) 
    {
        if (!enif_get_list_cell(env, currentList, &head, &tail))  {
            return false;
        }
        currentList = tail;
        if (!enif_get_double(env, head, &headVal)) {
            if (!enif_get_int(env, head, &intVal)) {
                return false;
            }
            headVal = intVal;
        }
        outVector[i] = headVal;
    }

    return true;
}

static inline
bool two_vectors_argv(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[],
    numy::Tensor*& tensor1, numy::Tensor*& tensor2)
{
    if (argc != 2) {
        return false;
    }

    tensor1 = numy::tnsr::getTensor(env, argv[0]);
    tensor2 = numy::tnsr::getTensor(env, argv[1]);

    if (tensor1 == nullptr or !tensor1->isValid() or
        tensor2 == nullptr or !tensor2->isValid())
    {
	    return false;
    }

    return true;
}

ERL_NIF_TERM numy_vector_dot_product(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    numy::Tensor* tensor1 {nullptr};
    numy::Tensor* tensor2 {nullptr};

    if (!two_vectors_argv(env, argc, argv, tensor1, tensor2)) {
        return enif_make_badarg(env);
    }

    unsigned int length = std::min(tensor1->nrElements, tensor2->nrElements);

    ERL_NIF_TERM retVal = enif_make_double(env,
        dot_vectors(tensor1->dbl_data(), tensor2->dbl_data(), length));

    return retVal;
}

using VectorFunOP2 = void (*)(double a[], const double b[], unsigned length);

static
ERL_NIF_TERM numy_vector__op2(ErlNifEnv* env, int argc,
    const ERL_NIF_TERM argv[], VectorFunOP2 op)
{
    numy::Tensor* tensor1 {nullptr};
    numy::Tensor* tensor2 {nullptr};

    if (!two_vectors_argv(env, argc, argv, tensor1, tensor2)) {
        return enif_make_badarg(env);
    }

    unsigned int length = std::min(tensor1->nrElements, tensor2->nrElements);

    op(tensor1->dbl_data(), tensor2->dbl_data(), length);

    return numy::tnsr::getOkAtom(env);
}

ERL_NIF_TERM numy_vector_add(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    return numy_vector__op2(env, argc, argv, add_vectors);
}

ERL_NIF_TERM numy_vector_sub(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    return numy_vector__op2(env, argc, argv, sub_vectors);
}

ERL_NIF_TERM numy_vector_mul(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    return numy_vector__op2(env, argc, argv, mul_vectors);
}

ERL_NIF_TERM numy_vector_div(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    return numy_vector__op2(env, argc, argv, div_vectors);
}

ERL_NIF_TERM numy_vector_at(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 2) {
        return enif_make_badarg(env);
    }

    const numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or !tensor->isValid()) {
	    return enif_make_badarg(env);
    }

    int index{0};
    if (!enif_get_int(env, argv[1], &index)) {
        return enif_make_badarg(env);
    }

    if (index < 0 or index >= (int)tensor->nrElements) {
        return enif_make_badarg(env);
    }

    const double* data = (double*) tensor->data;

    double val = data[index];

    return enif_make_double(env, val);
}

ERL_NIF_TERM numy_vector_equal(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    numy::Tensor* tensor1 {nullptr};
    numy::Tensor* tensor2 {nullptr};

    if (!two_vectors_argv(env, argc, argv, tensor1, tensor2)) {
        return enif_make_badarg(env);
    }

    unsigned int length = std::min(tensor1->nrElements, tensor2->nrElements);

    bool equal = vectors_equal(tensor1->dbl_data(), tensor2->dbl_data(), length);

    return numy::tnsr::getBoolAtom(env, equal);
}