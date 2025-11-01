#!/usr/bin/env bash
# I/O тесты с опциональным запуском под Valgrind.
# Переменные окружения (можно задавать через make):
#   BIN=./app
#   DIR=tests/io
#   TIMEOUT=5           # сек на тест
#   USE_VALGRIND=0/1
#   NORMALIZE_WS=0/1    # 1 = игнорировать хвостовые пробелы/CRLF при сравнении

set -u  # не set -e, чтобы собрать все упавшие кейсы
BIN="${BIN:-./app}"
DIR="${DIR:-tests/io}"
TIMEOUT="${TIMEOUT:-5}"
USE_VALGRIND="${USE_VALGRIND:-0}"
NORMALIZE_WS="${NORMALIZE_WS:-0}"

if [ ! -x "$BIN" ]; then
  echo "ERROR: $BIN not found or not executable"
  exit 1
fi

shopt -s nullglob
cases=( "$DIR"/*.in )
if [ ${#cases[@]} -eq 0 ]; then
  echo "No *.in files in $DIR"
  exit 0
fi

FAILED=0

for in_file in "${cases[@]}"; do
  base="$(basename "$in_file" .in)"
  out_file="$DIR/$base.out"
  args_file="$DIR/$base.args"
  tmp_out="$(mktemp)"

  if [ ! -f "$out_file" ]; then
    echo "[$base] MISSING expected file: $out_file"
    FAILED=1
    continue
  fi

  args=""
  if [ -f "$args_file" ]; then
    # читаем аргументы как одну строку
    args="$(cat "$args_file")"
  fi

  echo "== [$base] =="
  if [ "$USE_VALGRIND" = "1" ]; then
    VG="valgrind --quiet \
       --leak-check=full --show-leak-kinds=all \
       --track-origins=yes \
       --errors-for-leak-kinds=definite \
       --error-exitcode=101"
  else
    VG=""
  fi

  # защита от зависаний
  if ! timeout "${TIMEOUT}s" bash -c "$VG $BIN $args < \"$in_file\" > \"$tmp_out\""; then
    code=$?
    if [ "$code" -eq 124 ]; then
      echo "  TIMEOUT (> ${TIMEOUT}s)"
    elif [ "$code" -eq 101 ]; then
      echo "  VALGRIND: leaks/errors detected"
    else
      echo "  RUNTIME ERROR (exit=$code)"
    fi
    FAILED=1
  else
    if [ "$NORMALIZE_WS" = "1" ]; then
      # нормализуем края строк и CRLF
      sed -e 's/[ \t]*$//' -e 's/\r$//' "$out_file" > "$out_file.norm"
      sed -e 's/[ \t]*$//' -e 's/\r$//' "$tmp_out"  > "$tmp_out.norm"
      DIFF_TO="$tmp_out.norm"; EXP_TO="$out_file.norm"
    else
      DIFF_TO="$tmp_out"; EXP_TO="$out_file"
    fi

    if ! diff -u "$EXP_TO" "$DIFF_TO"; then
      echo "  OUTPUT MISMATCH"
      FAILED=1
    else
      echo "  OK"
    fi

    [ "$NORMALIZE_WS" = "1" ] && rm -f "$out_file.norm" "$tmp_out.norm"
  fi

  rm -f "$tmp_out"
done

exit $FAILED
