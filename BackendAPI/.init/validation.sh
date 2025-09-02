#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/fitness-and-workout-tracker-16440-16573/BackendAPI"
cd "${WORKSPACE}"
BUILD_LOG="${WORKSPACE}/build.log"
SERVE_LOG="${WORKSPACE}/serve.log"
# build
npm run build >"${BUILD_LOG}" 2>&1 || { echo "ERROR: build failed; see ${BUILD_LOG}" >&2; tail -n 200 "${BUILD_LOG}" >&2; exit 60; }
[ -d build ] || { echo "ERROR: build directory missing after build" >&2; tail -n 200 "${BUILD_LOG}" >&2; exit 61; }
SERVE_BIN="${WORKSPACE}/node_modules/.bin/serve"
[ -x "${SERVE_BIN}" ] || { echo "ERROR: local serve binary missing" >&2; exit 62; }
# choose port: allow override, else probe candidates
if [ -n "${VALIDATION_PORT-}" ]; then
  PORT=${VALIDATION_PORT}
else
  PORT=0
  for p in 5000 5001 5002 5003 5004 5005 5006 5007 5008 5009 5010; do
    if ! ss -ltn "sport = :${p}" >/dev/null 2>&1; then PORT=${p}; break; fi
  done
  if [ "${PORT}" -eq 0 ]; then echo "ERROR: no free port found for validation" >&2; exit 63; fi
fi
# start serve
"${SERVE_BIN}" -s build -l "${PORT}" >"${SERVE_LOG}" 2>&1 &
SERVER_PID=$!
trap 'kill ${SERVER_PID} >/dev/null 2>&1 || true' EXIT
# readiness loop
READY=0
for i in $(seq 1 60); do
  if ! kill -0 ${SERVER_PID} >/dev/null 2>&1; then
    echo "ERROR: serve process exited prematurely; see ${SERVE_LOG}" >&2; tail -n 200 "${SERVE_LOG}" >&2; exit 64
  fi
  if curl -sS --fail http://127.0.0.1:${PORT}/ >/dev/null 2>&1; then READY=1; break; fi
  sleep 1
done
if [ "${READY}" -ne 1 ]; then echo "ERROR: server did not become ready; see ${SERVE_LOG}" >&2; tail -n 200 "${SERVE_LOG}" >&2; kill ${SERVER_PID} >/dev/null 2>&1 || true; exit 65; fi
# verify HTML
HTML=$(curl -sS http://127.0.0.1:${PORT}/ || true)
if ! echo "${HTML}" | grep -qi "<!doctype html>"; then echo "ERROR: validation failed: root did not return html" >&2; tail -n 200 "${SERVE_LOG}" >&2; kill ${SERVER_PID} >/dev/null 2>&1 || true; exit 66; fi
# cleanup
kill ${SERVER_PID} >/dev/null 2>&1 || true
wait ${SERVER_PID} 2>/dev/null || true
echo "validation ok"
exit 0
