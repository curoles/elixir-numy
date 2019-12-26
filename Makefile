# Numy C code compilation.
#
# Author: Igor Lesik 2019

ifndef MIX_ENV
$(error MIX_ENV is not set, check Mix.Tasks.Compile.Numy.run())
endif

ifndef NUMY_VERSION
$(error NUMY_VERSION is not set
endif

ifneq (${MIX_ENV},prod) # MIX_ENV=prod | dev | test
  DEBUG=1
endif

ERLANG_INC := $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)

# CFLAGS for both Debug and Release
CFLAGS += -Werror -Wfatal-errors -Wall -Wextra
CFLAGS += -I$(ERLANG_INC)
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

NUMY_VECTOR_LIB := priv/libnumy_vector_${MIX_ENV}.so
NUMY_LAPACK_LIB := priv/libnumy_lapack_${MIX_ENV}.so

.PHONY: all
all: ${NUMY_VECTOR_LIB} ${NUMY_LAPACK_LIB}

NUMY_VECTOR_SRC := ./nifs/vector.cpp
NUMY_LAPACK_SRC := ./nifs/lapack/netlib/lapack.cpp

${NUMY_LAPACK_LIB}: ${NUMY_LAPACK_SRC}
	@mkdir -p ./priv
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@
	@ln -srf $@ priv/libnumy_lapack.so

${NUMY_VECTOR_LIB}: ${NUMY_VECTOR_SRC}
	@mkdir -p ./priv
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@
	@ln -srf $@ priv/libnumy_vector.so