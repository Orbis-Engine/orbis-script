#!/bin/bash
# Analyzes and tests everything in the scripting runtime.
set -uo pipefail
cd "$(dirname "$0")/.."

PACKAGES=(packages/orbis_script packages/orbis_script_codegen)

# The interface layer is the one package here that draws anything, so it
# resolves and runs with Flutter rather than Dart.
FLUTTER_PACKAGES=(packages/orbis_script_ui)
failures=0

for package in "${PACKAGES[@]}"; do
  echo "== $package =="
  (cd "$package" && dart pub get > /dev/null 2>&1)

  if (cd "$package" && dart analyze > /tmp/orbis_analyze.log 2>&1); then
    echo "  ok    analyze"
  else
    echo "  FAIL  analyze"; tail -20 /tmp/orbis_analyze.log; failures=$((failures+1))
  fi

  if (cd "$package" && dart test > /tmp/orbis_test.log 2>&1); then
    summary=$(tr '\r' '\n' < /tmp/orbis_test.log | tail -1 \
      | sed -e 's/\x1b\[[0-9;]*m//g' -e 's/^[0-9:]* //')
    echo "  ok    $summary"
  else
    echo "  FAIL  tests"; tail -25 /tmp/orbis_test.log; failures=$((failures+1))
  fi
done

for package in "${FLUTTER_PACKAGES[@]}"; do
  echo "== $package =="
  if ! command -v flutter > /dev/null; then
    echo "  skip  no flutter on PATH"
    continue
  fi
  (cd "$package" && flutter pub get > /dev/null 2>&1)

  if (cd "$package" && dart analyze > /tmp/orbis_analyze.log 2>&1); then
    echo "  ok    analyze"
  else
    echo "  FAIL  analyze"; tail -20 /tmp/orbis_analyze.log; failures=$((failures+1))
  fi

  if (cd "$package" && flutter test > /tmp/orbis_test.log 2>&1); then
    summary=$(tr '\r' '\n' < /tmp/orbis_test.log | tail -1 \
      | sed -e 's/\x1b\[[0-9;]*m//g' -e 's/^[0-9:]* //')
    echo "  ok    $summary"
  else
    echo "  FAIL  tests"; tail -25 /tmp/orbis_test.log; failures=$((failures+1))
  fi
done

echo "== typings =="
./tool/check_typings.sh || failures=$((failures+1))

echo
[ "$failures" -eq 0 ] && echo "everything green" || echo "$failures failing step(s)"
exit "$failures"
