#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/home/kavia/workspace/code-generation/fitness-and-workout-tracker-16440-16573/BackendAPI"
cd "${WORKSPACE}"
[ -f package.json ] || { echo "ERROR: package.json missing in workspace." >&2; exit 40; }
INSTALL_LOG="${WORKSPACE}/install.log"
NPM_CMD=(npm)
if [ "$(id -u)" -eq 0 ]; then NPM_CMD+=(--unsafe-perm); fi
# run install/ci and capture logs
if [ -f package-lock.json ]; then
  "${NPM_CMD[@]}" ci --no-audit --no-fund >"${INSTALL_LOG}" 2>&1 || { echo "ERROR: npm ci failed; see ${INSTALL_LOG}" >&2; tail -n 200 "${INSTALL_LOG}" >&2; exit 41; }
else
  "${NPM_CMD[@]}" install --no-audit --no-fund >"${INSTALL_LOG}" 2>&1 || { echo "ERROR: npm install failed; see ${INSTALL_LOG}" >&2; tail -n 200 "${INSTALL_LOG}" >&2; exit 42; }
fi
NODE_MODULES_BIN="${WORKSPACE}/node_modules/.bin"
# ensure jest present
if [ ! -x "${NODE_MODULES_BIN}/jest" ]; then
  "${NPM_CMD[@]}" i --no-audit --no-fund --save-dev jest >>"${INSTALL_LOG}" 2>&1 || { echo "ERROR: installing jest failed; see ${INSTALL_LOG}" >&2; tail -n 200 "${INSTALL_LOG}" >&2; exit 43; }
fi
# ensure serve present
if [ ! -x "${NODE_MODULES_BIN}/serve" ]; then
  "${NPM_CMD[@]}" i --no-audit --no-fund --save-dev serve >>"${INSTALL_LOG}" 2>&1 || { echo "ERROR: installing serve failed; see ${INSTALL_LOG}" >&2; tail -n 200 "${INSTALL_LOG}" >&2; exit 44; }
fi
# verify key binaries
[ -x "${NODE_MODULES_BIN}/react-scripts" ] || true
[ -x "${NODE_MODULES_BIN}/jest" ] || { echo "ERROR: jest missing after installs" >&2; tail -n 200 "${INSTALL_LOG}" >&2; exit 45; }
[ -x "${NODE_MODULES_BIN}/serve" ] || { echo "ERROR: serve missing after installs" >&2; tail -n 200 "${INSTALL_LOG}" >&2; exit 46; }
node -v && npm -v
exit 0
