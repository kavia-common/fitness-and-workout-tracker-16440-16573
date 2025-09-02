#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/fitness-and-workout-tracker-16440-16573/BackendAPI"
cd "${WORKSPACE}"
TEST_LOG="${WORKSPACE}/test.log"
# run tests if script present; fail unless SKIP_TEST_FAILURES=1
if jq -e '.scripts.test' package.json >/dev/null 2>&1; then
  npm test --silent -- --runInBand >"${TEST_LOG}" 2>&1 || {
    if [ "${SKIP_TEST_FAILURES-0}" = "1" ]; then echo "tests failed but SKIP_TEST_FAILURES=1; continuing"; else echo "ERROR: tests failed; see ${TEST_LOG}" >&2; tail -n 200 "${TEST_LOG}" >&2; exit 70; fi
  }
  echo "tests ok"
else
  echo "no test script configured; skipping tests"
fi
