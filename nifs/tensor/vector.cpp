/**
 * @file
 * @brief     Typical vector operations.
 * @author    Igor Lesik 2019
 * @copyright Igor Lesik 2019
 *
 */
#include "vector.hpp"

#include <algorithm>
#include <functional>
#include <cmath>
#include <cassert>

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

static inline
void axpby_vectors(double a[], const double b[], unsigned length,
    double factor_a, double factor_b)
{
    #pragma GCC ivdep
    for (unsigned int i = 0; i < length; ++i) {
        a[i] = factor_b * b[i] + factor_a * a[i];
    }
}

static
unsigned vector_copy_range(
    double a[], unsigned offset_a, unsigned stride_a, unsigned len_a,
    const double b[], unsigned offset_b, unsigned stride_b, unsigned len_b,
    unsigned count)
{
    assert(stride_a > 0 and stride_b > 0);
    assert(offset_a < len_a and offset_b < len_b);

    unsigned size_a = (len_a - offset_a) / stride_a;
    unsigned size_b = (len_b - offset_b) / stride_b;

    count = std::min(count, std::min(size_a, size_b));

    for (unsigned pos_a = offset_a, pos_b = offset_b, i = 0; i < count;
        ++i, pos_a += stride_a, pos_b += stride_b)
    {
        a[pos_a] = b[pos_b];
    }

    return count;
}

static inline
void negate_vector(double a[], unsigned length)
{
    #pragma GCC ivdep
    for (unsigned int i = 0; i < length; ++i) {
        a[i] = -a[i];
    }
}

static
int find_in_vector(const double a[], unsigned length, double val)
{
    int pos {-1};

    const double* end_a = a + length;

    const double* p = std::find(a, end_a, val);
    if (p != end_a) {
        pos = (p - a);
    }

    return pos;
}

static
void vectors_swap_ranges(double a[], unsigned len_a, unsigned offset_a,
                         double b[], unsigned len_b, unsigned offset_b)
{
    offset_a = std::min(len_a, offset_a);
    offset_b = std::min(len_b, offset_b);

    double* begin_a = a + offset_a;
    double* begin_b = b + offset_b;

    len_a -= offset_a;
    len_b -= offset_b;

    unsigned len = std::min(len_a, len_b);

    std::swap_ranges(begin_a, begin_a + len, begin_b);
}

enum SETOP {SETOP_UNION, SETOP_INTERSECTION, SETOP_DIFF, SETOP_SYMM_DIFF};

static
void vector_setop(double a[], unsigned len_a,
                  double b[], unsigned len_b,
                  SETOP op, std::vector<double>& v)
{
    std::sort(a, a + len_a);
    std::sort(b, b + len_b);

    v.resize(len_a + len_b);
    std::vector<double>::iterator it;

    switch (op) {
        case SETOP_UNION:
            it = std::set_union(a, a+len_a, b, b+len_b, v.begin());
            break;
        case SETOP_INTERSECTION:
            it = std::set_intersection(a, a+len_a, b, b+len_b, v.begin());
            break;
        case SETOP_DIFF:
            it = std::set_difference(a, a+len_a, b, b+len_b, v.begin());
            break;
        case SETOP_SYMM_DIFF:
            it = std::set_symmetric_difference(a, a+len_a, b, b+len_b, v.begin());
            break;
    }

    v.resize(it - v.begin());
}

bool tensor_save_to_file(numy::Tensor& tensor, const char* filename)
{
    FILE* f = std::fopen(filename, "w");
    if (f == nullptr) return false;

    size_t hsz = std::fwrite(&tensor , sizeof(tensor), 1, f);
    size_t dsz = std::fwrite(tensor.data, 1, tensor.dataSize, f);

    std::fclose(f);

    return hsz == 1 and dsz == tensor.dataSize;
}

bool tensor_load_from_file(numy::Tensor& tensor, const char* filename)
{
    FILE* f = std::fopen(filename, "r");
    if (f == nullptr) return false;

    size_t hsz = std::fread(&tensor , sizeof(tensor), 1, f);

    bool header_ok = hsz == 1 and tensor.magic == tensor.MAGIC;

    bool data_ok {false};

    if (header_ok and tensor.nrElements > 0 and tensor.dataSize > 0) {
        tensor.data = enif_alloc(tensor.dataSize);
        size_t dsz = std::fread(tensor.data, 1, tensor.dataSize, f);
        data_ok = (dsz == tensor.dataSize);
    }

    std::fclose(f);

    return header_ok and data_ok;
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

ERL_NIF_TERM numy_vector_get_at(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
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

    if (index < 0) {
        index = tensor->nrElements + index;
    }

    if (index < 0 or index >= (int)tensor->nrElements) {
        return enif_make_badarg(env);
    }

    const double* data = (double*) tensor->data;

    double val = data[index];

    return enif_make_double(env, val);
}

ERL_NIF_TERM numy_vector_set_at(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 3) {
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

    if (index < 0) {
        index = tensor->nrElements + index;
    }

    if (index < 0 or index >= (int)tensor->nrElements) {
        return enif_make_badarg(env);
    }

    double val {0.0};
    if (!enif_get_double(env, argv[2], &val)) {
        int64_t intVal {0}; if (!enif_get_int64(env, argv[2], &intVal)) {
            return enif_make_badarg(env);
        }
        val = intVal;
    }

    double* data = (double*) tensor->data;

    data[index] = val;

    return numy::tnsr::getOkAtom(env);
}

ERL_NIF_TERM numy_vector_assign_all(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 2) {
        return enif_make_badarg(env);
    }

    const numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or !tensor->isValid()) {
	    return enif_make_badarg(env);
    }

    double val {0.0};
    if (!enif_get_double(env, argv[1], &val)) {
        int64_t intVal {0}; if (!enif_get_int64(env, argv[1], &intVal)) {
            return enif_make_badarg(env);
        }
        val = intVal;
    }

    double* data = (double*) tensor->data;

    #pragma GCC ivdep
    for (unsigned i = 0; i < tensor->nrElements; ++i) {
        data[i] = val;
    }

    return numy::tnsr::getOkAtom(env);
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

ERL_NIF_TERM numy_vector_sort(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 1) {
        return enif_make_badarg(env);
    }

    numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or !tensor->isValid()) {
	    return enif_make_badarg(env);
    }

    double* x = tensor->dbl_data();

    std::sort(x, &x[tensor->nrElements], std::less<double>());

    return numy::tnsr::getOkAtom(env);
}

ERL_NIF_TERM numy_vector_reverse(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 1) {
        return enif_make_badarg(env);
    }

    numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or !tensor->isValid()) {
	    return enif_make_badarg(env);
    }

    double* x = tensor->dbl_data();

    std::reverse(x, &x[tensor->nrElements]);

    return numy::tnsr::getOkAtom(env);
}

ERL_NIF_TERM numy_vector_axpby(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 4) {
        return enif_make_badarg(env);
    }

    const numy::Tensor* tensor1 = numy::tnsr::getTensor(env, argv[0]);
    const numy::Tensor* tensor2 = numy::tnsr::getTensor(env, argv[1]);

    if (tensor1 == nullptr or !tensor1->isValid() or tensor2 == nullptr or !tensor2->isValid()) {
	    return enif_make_badarg(env);
    }

    double factor_a {0.0};
    if (!enif_get_double(env, argv[2], &factor_a)) {
        int64_t intVal {0}; if (!enif_get_int64(env, argv[2], &intVal)) {
            return enif_make_badarg(env);
        }
        factor_a = intVal;
    }

    double factor_b {0.0};
    if (!enif_get_double(env, argv[3], &factor_a)) {
        int64_t intVal {0}; if (!enif_get_int64(env, argv[3], &intVal)) {
            return enif_make_badarg(env);
        }
        factor_b = intVal;
    }

    double* a = (double*) tensor1->data;
    double* b = (double*) tensor2->data;

    unsigned length = std::min(tensor1->nrElements, tensor2->nrElements);

    #pragma GCC ivdep
    for (unsigned i = 0; i < length; ++i) {
        a[i] = factor_a * a[i] + factor_b * b[i];
    }

    return numy::tnsr::getOkAtom(env);
}

ERL_NIF_TERM numy_mapset_op(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 3) {
        return enif_make_badarg(env);
    }

    numy::Tensor* tensor1 = numy::tnsr::getTensor(env, argv[0]);
    numy::Tensor* tensor2 = numy::tnsr::getTensor(env, argv[1]);

    if (tensor1 == nullptr or !tensor1->isValid() or
        tensor2 == nullptr or !tensor2->isValid())
    {
	    return enif_make_badarg(env);
    }

    enum SETOP op {SETOP_UNION};
    
    //switch (atom){SETOP_UNION, SETOP_INTERSECTION, SETOP_DIFF, SETOP_SYMM_DIFF};

    std::vector<double> resv;

    vector_setop(tensor1->dbl_data(), tensor1->nrElements,
                 tensor2->dbl_data(), tensor2->nrElements, op, resv);
 
    //FIXME TODO XXXXXXXXXXXXXX from resv make List

    return numy::tnsr::getOkAtom(env);
}

ERL_NIF_TERM numy_vector_swap_ranges(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 4) {
        return enif_make_badarg(env);
    }

    numy::Tensor* tensor1 = numy::tnsr::getTensor(env, argv[0]);
    numy::Tensor* tensor2 = numy::tnsr::getTensor(env, argv[1]);

    if (tensor1 == nullptr or !tensor1->isValid() or
        tensor2 == nullptr or !tensor2->isValid())
    {
	    return enif_make_badarg(env);
    }

    //read offsets XXXXXXXXXXXXXXXXXXXXX

    vectors_swap_ranges(tensor1->dbl_data(), tensor1->nrElements, /*offset_a*/0,
                        tensor2->dbl_data(), tensor2->nrElements, /*off_b*/0);

    return numy::tnsr::getOkAtom(env);
}

ERL_NIF_TERM numy_vector_find(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 2) {
        return enif_make_badarg(env);
    }

    numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or !tensor->isValid()) {
	    return enif_make_badarg(env);
    }

    double val {0.0};
    if (!enif_get_double(env, argv[1], &val)) {
        int64_t i; if (!enif_get_int64(env, argv[1], &i)) {
            return enif_make_badarg(env);
        }
        val = i;
    }

    int pos = find_in_vector(tensor->dbl_data(), tensor->nrElements, val);

    return enif_make_int(env, pos); // -1 if could not find
}

ERL_NIF_TERM numy_vector_negate(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 1) {
        return enif_make_badarg(env);
    }

    numy::Tensor* tensor = numy::tnsr::getTensor(env, argv[0]);

    if (tensor == nullptr or !tensor->isValid()) {
	    return enif_make_badarg(env);
    }

    negate_vector(tensor->dbl_data(), tensor->nrElements);

    return numy::tnsr::getOkAtom(env);
}


ERL_NIF_TERM numy_vector_copy_range(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 7) {
        return enif_make_badarg(env);
    }

    numy::Tensor* tensor1 = numy::tnsr::getTensor(env, argv[0]);
    numy::Tensor* tensor2 = numy::tnsr::getTensor(env, argv[1]);

    if (tensor1 == nullptr or !tensor1->isValid() or
        tensor2 == nullptr or !tensor2->isValid())
    {
	    return enif_make_badarg(env);
    }

    unsigned count;
    if (!enif_get_uint(env, argv[2], &count))
        return enif_make_badarg(env);

    unsigned offset_a;
    if (!enif_get_uint(env, argv[3], &offset_a))
        return enif_make_badarg(env);

    unsigned offset_b;
    if (!enif_get_uint(env, argv[4], &offset_b))
        return enif_make_badarg(env);

    unsigned stride_a;
    if (!enif_get_uint(env, argv[5], &stride_a))
        return enif_make_badarg(env);

    unsigned stride_b;
    if (!enif_get_uint(env, argv[6], &stride_b))
        return enif_make_badarg(env);

    if (stride_a == 0 or stride_b == 0)
        return enif_make_badarg(env);

    unsigned nrCopied = vector_copy_range(
        tensor1->dbl_data(), offset_a, stride_a, tensor1->nrElements,
        tensor2->dbl_data(), offset_b, stride_b, tensor2->nrElements,
        count);

    return enif_make_uint(env, nrCopied);
}
