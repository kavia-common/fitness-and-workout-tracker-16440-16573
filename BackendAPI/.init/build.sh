#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/fitness-and-workout-tracker-16440-16573/BackendAPI"
cd "${WORKSPACE}"
BUILD_LOG="${WORKSPACE}/build.log"
# run build and capture logs
npm run build >"${BUILD_LOG}" 2>&1 || { echo "ERROR: build failed; see ${BUILD_LOG}" >&2; tail -n 200 "${BUILD_LOG}" >&2; exit 60; }
[ -d "${WORKSPACE}/build" ] || { echo "ERROR: build directory missing after build" >&2; tail -n 200 "${BUILD_LOG}" >&2; exit 61; }
echo "build ok"
