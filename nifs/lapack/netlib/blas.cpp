/**
 * @file
 * @brief     BLAS functions
 * @author    Igor Lesik 2019
 * @copyright Igor Lesik 2019
 *
 */
#include "lapack/netlib/blas.hpp"

#include <cblas.h> 

#include "tensor/tensor.hpp"
#include "tensor/nif_resource.hpp"

#define UNUSED __attribute__((unused))
#define DLL_LOCAL __attribute__ ((visibility ("hidden")))

#define NUMY_ERL_FUN ERL_NIF_TERM DLL_LOCAL

//https://en.wikipedia.org/wiki/Givens_rotation
//http://www.netlib.org/lapack/explore-html/df/d28/group__single__blas__level1_ga2f65d66137ddaeb7ae93fcc4902de3fc.html#ga2f65d66137ddaeb7ae93fcc4902de3fc
NUMY_ERL_FUN numy_blas_drotg(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
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

    // XXX TODO XXX

    return numy::tnsr::getOkAtom(env);
}
