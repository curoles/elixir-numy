# Numy C code compilation.
#
# Author: Igor Lesik 2019

ifndef MIX_ENV
$(error MIX_ENV is not set, check Mix.Tasks.Compile.Numy.run())
endif

ifneq (${MIX_ENV},prod) # MIX_ENV=prod | dev | test
  DEBUG=1
endif

ERLANG_INC := $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)

# CFLAGS for both Debug and Release
CFLAGS += -Werror -Wfatal-errors -Wall -Wextra
CFLAGS += -I$(ERLANG_INC)
CFLAGS += -fpic -std=c++17
CFALGS += -fno-rtti

LDFLAGS += -shared

ifdef DEBUG
CFLAGS += -Og -g
CFLAGS += -fsanitize=address -fsanitize=undefined
else
CFLAGS += -O3 -DNDEBUG
endif

NUMY_LIB := priv/libnumy_${MIX_ENV}.so

.PHONY: all
all: ${NUMY_LIB}

NUMY_SRC := ./nifs/lapack/netlib/lapack.cpp

${NUMY_LIB}: ${NUMY_SRC}
	@mkdir -p ./priv
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@