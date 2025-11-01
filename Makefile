# =========================
#   Makefile (I/O + Valgrind only)
# =========================
.DEFAULT_GOAL := test

CC      ?= gcc
CFLAGS  ?= -Wall -Wextra -Werror -std=c11 -O0 -g -Iinclude
LDFLAGS ?=

SRC  := $(wildcard src/*.c)
OBJ  := $(SRC:.c=.o)
BIN  := app

# --- настройки тестов ---
TEST_DIR     ?= tests/io
TIMEOUT      ?= 10
NORMALIZE_WS ?= 0   # 1 — игнорировать хвостовые пробелы/CRLF при сравнении

VALGRIND ?= valgrind --quiet \
  --leak-check=full --show-leak-kinds=all \
  --track-origins=yes \
  --errors-for-leak-kinds=definite \
  --error-exitcode=101

.PHONY: all clean test ensure-runner

# -------- Build --------
all: $(BIN)

$(BIN): $(OBJ)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# -------- Tests --------
test: ensure-runner $(BIN)
	@echo "== Running all I/O tests under Valgrind =="
	BIN=./$(BIN) DIR=$(TEST_DIR) TIMEOUT=$(TIMEOUT) USE_VALGRIND=1 NORMALIZE_WS=$(NORMALIZE_WS) \
	./tests/run_io_tests.sh

# Проверка наличия скрипта и тестов
ensure-runner:
	@if [ ! -x tests/run_io_tests.sh ]; then \
	  if [ -f tests/run_io_tests.sh ]; then chmod +x tests/run_io_tests.sh; \
	  else echo "ERROR: tests/run_io_tests.sh not found"; exit 1; fi \
	fi
	@if [ -z "$$(ls -1 $(TEST_DIR)/*.in 2>/dev/null)" ]; then \
	  echo "WARNING: No .in files in $(TEST_DIR) — nothing to test."; \
	fi

# -------- Clean --------
clean:
	$(RM) $(OBJ) $(BIN)
