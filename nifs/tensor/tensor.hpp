/**
 * @file
 * @brief     Tensor is a multi-dimentional matrix (sometimes caled ND-Array)
 *            contaning elements of a single data type.
 * @author    Igor Lesik 2019
 * @copyright Igor Lesik 2019
 *
 */
#pragma once

#include <cstdint>

namespace numy {

struct Tensor
{
    static unsigned constexpr MAX_DIMS = 32;
    static uint64_t constexpr MAGIC = 0xbadc01dc0ffe;

    uint64_t magic = MAGIC; ///< to check we are actually dealing with Tensor

    unsigned nrDims; ///< number of dimensions
    unsigned shape[MAX_DIMS]; ///< size of each dimension 

    void* data;

    unsigned nrElements;
    unsigned dataSize; /// size of data in bytes

    inline bool isValid() const {
        return nrDims > 0 and nrDims < MAX_DIMS and data != nullptr;
    }

    inline unsigned nr_cols() const {
        return shape[0];
    }

    inline unsigned nr_rows() const {
        return (nrDims == 1)? 1u : shape[1];
    }
};

} // end of namespace numy