CC ?= gcc
CFLAGS ?= -Wall -Wextra -Werror -std=c11 -O2 -Iinclude
LDFLAGS ?=

SRC := $(wildcard src/*.c)
OBJ := $(SRC:.c=.o)

BIN := app
MAIN := main.c                 
TESTS_SRC := $(wildcard tests/*.c)
TESTS_BIN := tests_runner
TEST_LIBS := -lcriterion

.PHONY: all clean test

all: $(BIN)

$(BIN): $(OBJ) $(MAIN)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

$(TESTS_BIN): $(TESTS_SRC) $(OBJ)
	$(CC) $(CFLAGS) $^ -o $@ $(TEST_LIBS) $(LDFLAGS)

test: $(TESTS_BIN)
	./$(TESTS_BIN) --verbose

clean:
	$(RM) $(OBJ) $(BIN) $(TESTS_BIN)
