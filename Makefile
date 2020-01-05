# Numy C code compilation.
#
# Author: Igor Lesik 2019

ifndef MIX_ENV
$(error MIX_ENV is not set)
endif

ifndef NUMY_VERSION
$(error NUMY_VERSION is not set)
endif

ifneq (${MIX_ENV},prod) # MIX_ENV=prod | dev | test
  DEBUG=1
endif

ERLANG_INC := $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)

# CFLAGS for both Debug and Release
CFLAGS += -Werror -Wfatal-errors -Wall -Wextra
CFLAGS += -I$(ERLANG_INC) -I./nifs
CFLAGS += -fpic -std=c++17
CFLAGS += -fno-rtti -fno-exceptions
CFLAGS += -DNUMY_VERSION=${NUMY_VERSION}

LDFLAGS += -shared

ifdef DEBUG
CFLAGS += -Og -g
CFLAGS += -fsanitize=undefined
else
CFLAGS += -O3 -DNDEBUG
endif

NETLIB_LAPACK_LIBS := -llapacke -llapack -lblas -lgfortran

#NUMY_VECTOR_LIB := priv/libnumy_vector_${MIX_ENV}.so
#NUMY_TENSOR_LIB := priv/libnumy_tensor_${MIX_ENV}.so
NUMY_LAPACK_LIB := priv/libnumy_lapack_${MIX_ENV}.so

.PHONY: all
all: ${NUMY_VECTOR_LIB} ${NUMY_TENSOR_LIB} ${NUMY_LAPACK_LIB}

#NUMY_VECTOR_SRC := ./nifs/vector.cpp
#NUMY_TENSOR_SRC := ./nifs/tensor/tensor.cpp

NUMY_LAPACK_SRC := ./nifs/lapack/netlib/lapack.cpp ./nifs/tensor/vector.cpp
NUMY_LAPACK_SRC += ./nifs/lapack/netlib/blas.cpp

NUMY_LAPACK_DEPS := ./nifs/tensor/tensor.hpp ./nifs/tensor/nif_resource.hpp
NUMY_LAPACK_DEPS += ./nifs/tensor/vector.hpp ./nifs/lapack/netlib/blas.hpp

./nifs/lapack/netlib/lapack.cpp: ${NUMY_LAPACK_DEPS}
	@touch $@

${NUMY_LAPACK_LIB}: ${NUMY_LAPACK_SRC}
	@mkdir -p ./priv
	@$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@ ${NETLIB_LAPACK_LIBS}
	@ln -srf $@ priv/libnumy_lapack.so

#${NUMY_VECTOR_LIB}: ${NUMY_VECTOR_SRC}
#	@mkdir -p ./priv
#	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@
#	@ln -srf $@ priv/libnumy_vector.so

#${NUMY_TENSOR_LIB}: ${NUMY_TENSOR_SRC}
#	@mkdir -p ./priv
#	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@
#	@ln -srf $@ priv/libnumy_tensor.so

.PHONY: clean
clean:
	rm -f ${NUMY_LAPACK_LIB}
	#rm -f ${NUMY_VECTOR_LIB}
	#rm -f ${NUMY_TENSOR_LIB}
