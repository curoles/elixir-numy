/**
 * @file
 * @brief     Typical vector operations.
 * @author    Igor Lesik 2019
 * @copyright Igor Lesik 2019
 *
 */
#include "vector.hpp"

#include <algorithm>
#include <cmath>

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

static inline
double vector_sum(double a[], unsigned length)
{
    double sum {0.0};

    #pragma GCC ivdep
    for (unsigned int i = 0; i < length; ++i) {
        sum += a[i];
    }

    return sum;
}

static inline
unsigned int vector_max(double a[], unsigned length)
{
    unsigned int pos {0};
    double max_val {a[0]};

    for (unsigned int i = 0; i < length; ++i) {
        if (a[i] > max_val) {
            pos = i;
            max_val = a[i];
        }
    }

    return pos;
}

static inline
unsigned int vector_min(double a[], unsigned length)
{
    unsigned int pos {0};
    double min_val {a[0]};

    for (unsigned int i = 0; i < length; ++i) {
        if (a[i] < min_val) {
            pos = i;
            min_val = a[i];
        }
    }

    return pos;
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

static inline
bool vector_fnum_argv(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[],
    numy::Tensor*& tensor, double& param)
{
    if (argc != 2) {
        return false;
    }

    tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or !tensor->isValid()) {
	    return false;
    }

    if (!enif_get_double(env, argv[1], &param)) {
        int64_t i = 0; if (!enif_get_int64(env, argv[1], &i)) {
            return false;
        }
        param = i;
    }

    return true;
}

ERL_NIF_TERM numy_vector_dot(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
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

ERL_NIF_TERM numy_vector_scale(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    numy::Tensor* tensor {nullptr};
    double factor {1.0};

    if (!vector_fnum_argv(env, argc, argv, tensor, factor)) {
        return enif_make_badarg(env);
    }

    double* data = tensor->dbl_data();

    #pragma GCC ivdep
    for (unsigned i = 0; i < tensor->nrElements; ++i) {
        data[i] *= factor;
    }

    return numy::tnsr::getOkAtom(env);
}

ERL_NIF_TERM numy_vector_offset(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    numy::Tensor* tensor {nullptr};
    double off {1.0};

    if (!vector_fnum_argv(env, argc, argv, tensor, off)) {
        return enif_make_badarg(env);
    }

    double* data = tensor->dbl_data();

    #pragma GCC ivdep
    for (unsigned i = 0; i < tensor->nrElements; ++i) {
        data[i] += off;
    }

    return numy::tnsr::getOkAtom(env);
}

ERL_NIF_TERM numy_vector_sum(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 1) {
        return enif_make_badarg(env);
    }

    numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or !tensor->isValid()) {
	    return enif_make_badarg(env);
    }

    return enif_make_double(env, vector_sum(tensor->dbl_data(), tensor->nrElements));
}

ERL_NIF_TERM numy_vector_max(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 1) {
        return enif_make_badarg(env);
    }

    numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or !tensor->isValid() or tensor->nrElements == 0) {
	    return enif_make_badarg(env);
    }

    double* data = tensor->dbl_data();
    unsigned int pos = vector_max(data, tensor->nrElements);

    if (pos >= tensor->nrElements) {
        enif_raise_exception(env, enif_make_atom(env, "error"));
    }

    return enif_make_double(env, data[pos]);
}

ERL_NIF_TERM numy_vector_min(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 1) {
        return enif_make_badarg(env);
    }

    numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or !tensor->isValid() or tensor->nrElements == 0) {
	    return enif_make_badarg(env);
    }

    double* data = tensor->dbl_data();
    unsigned int pos = vector_min(data, tensor->nrElements);

    if (pos >= tensor->nrElements) {
        enif_raise_exception(env, enif_make_atom(env, "error"));
    }

    return enif_make_double(env, data[pos]);
}

ERL_NIF_TERM numy_vector_max_index(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 1) {
        return enif_make_badarg(env);
    }

    numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or !tensor->isValid() or tensor->nrElements == 0) {
	    return enif_make_badarg(env);
    }

    unsigned int pos = vector_max(tensor->dbl_data(), tensor->nrElements);

    return enif_make_int(env, pos);
}

ERL_NIF_TERM numy_vector_min_index(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 1) {
        return enif_make_badarg(env);
    }

    numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or !tensor->isValid() or tensor->nrElements == 0) {
	    return enif_make_badarg(env);
    }

    unsigned int pos = vector_min(tensor->dbl_data(), tensor->nrElements);

    return enif_make_int(env, pos);
}

ERL_NIF_TERM numy_vector_heaviside(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    numy::Tensor* tensor {nullptr};
    double cutoff {0.0};

    if (!vector_fnum_argv(env, argc, argv, tensor, cutoff)) {
        return enif_make_badarg(env);
    }

    double* x = tensor->dbl_data();

    #pragma GCC ivdep
    for (unsigned i = 0; i < tensor->nrElements; ++i) {
        x[i] = (x[i] < cutoff)? 0.0 : 1.0;
    }

    return numy::tnsr::getOkAtom(env);
}

ERL_NIF_TERM numy_vector_sigmoid(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 1) {
        return enif_make_badarg(env);
    }

    numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or !tensor->isValid()) {
	    return enif_make_badarg(env);
    }

    double* x = tensor->dbl_data();

    #pragma GCC ivdep
    for (unsigned i = 0; i < tensor->nrElements; ++i) {
        x[i] = 1.0 / (1.0 + exp(-x[i]));
    }

    return numy::tnsr::getOkAtom(env);
}