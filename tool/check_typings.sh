#!/bin/bash
# Generates typings from a fixture manifest and puts them through tsc.
#
# The Dart tests check what the emitter writes; only a type checker can say
# whether it is usable. Both halves matter: valid script has to compile, and
# — more importantly — invalid script has to fail, because typings that permit
# a mistake are worse than none.
set -uo pipefail
cd "$(dirname "$0")/.."

command -v npm > /dev/null || { echo "skipped: npm not installed"; exit 0; }

FIXTURES=packages/orbis_script_codegen/test/fixtures
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

(cd packages/orbis_script_codegen \
  && dart run orbis_script_codegen "$OLDPWD/$FIXTURES" "$WORK/orbis.d.ts") \
  > /dev/null || exit 1

cp "$FIXTURES"/typescript/*.ts "$WORK/"
cd "$WORK"
npm install --silent --no-fund --no-audit typescript@5.7 > /dev/null 2>&1

# Listed in a project rather than passed as arguments: naming files on the
# command line makes tsc ignore tsconfig.json entirely, and the default target
# is old enough to reject BigInt64Array.
config() {
  cat > "tsconfig.$1.json" <<JSON
{
  "compilerOptions": {
    "strict": true, "noEmit": true, "target": "ES2022",
    "lib": ["ES2022"], "moduleResolution": "bundler", "module": "ESNext"
  },
  "files": ["orbis.d.ts", "$1.ts"]
}
JSON
}
config valid
config rejected

failures=0

if ./node_modules/.bin/tsc --project tsconfig.valid.json > /tmp/orbis_ts_valid.log 2>&1; then
  echo "  ok    valid script type-checks"
else
  echo "  FAIL  valid script should compile"; cat /tmp/orbis_ts_valid.log; failures=$((failures+1))
fi

errors=$(./node_modules/.bin/tsc --project tsconfig.rejected.json 2>&1 | grep -c 'error TS')
if [ "$errors" -ge 4 ]; then
  echo "  ok    invalid script rejected ($errors errors)"
else
  echo "  FAIL  expected at least 4 errors, saw $errors"; failures=$((failures+1))
fi

exit "$failures"
