#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/fitness-and-workout-tracker-16440-16573/BackendAPI"
cd "${WORKSPACE}"
SERVE_LOG="${WORKSPACE}/serve.log"
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
# start serve in background, write pid file
"${SERVE_BIN}" -s build -l "${PORT}" >"${SERVE_LOG}" 2>&1 &
SERVER_PID=$!
echo ${SERVER_PID} >"${WORKSPACE}/serve.pid"
echo "${PORT}" >"${WORKSPACE}/serve.port"
echo "started ${SERVER_PID} on ${PORT}"
