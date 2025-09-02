#!/usr/bin/env bash
set -euo pipefail
# Scaffolding script for minimal React app per step requirements
WORKSPACE="/home/kavia/workspace/code-generation/fitness-and-workout-tracker-16440-16573/BackendAPI"
LOG="$WORKSPACE/scaffold.log"
# 1) Environment checks (node and npm)
command -v node >/dev/null 2>&1 || { echo "ERROR: node not found" >&2; exit 10; }
command -v npm >/dev/null 2>&1 || { echo "ERROR: npm not found" >&2; exit 11; }
NODE_VER_MAJOR=$(node -v | sed 's/^v//' | cut -d. -f1)
if [ "${NODE_VER_MAJOR:-0}" -lt 16 ]; then
  echo "WARN: node major version is <16 (found $(node -v)). CRA/Vite prefer node>=16." >> /dev/stderr
fi
# Ensure workspace exists and is writable
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"
# Idempotent ownership change (if container has sudo and running as non-root this is a noop)
if [ "$(id -u)" -eq 0 ]; then
  chown -R "$(logname 2>/dev/null || echo root)":"$(logname 2>/dev/null || echo root)" "$WORKSPACE" 2>/dev/null || true
fi
# If package.json exists, skip scaffolding
if [ -f package.json ]; then
  echo "package.json exists; skipping scaffold." > "$LOG"
  exit 0
fi
# If workspace not empty, only allow scaffold when it won't overwrite project files
if [ "$(ls -A . 2>/dev/null || true)" != "" ]; then
  if [ -f package.json ] || [ -f src/index.js ] || [ -d public ]; then
    echo "ERROR: workspace has existing project files; refusing to scaffold to avoid overwriting." >&2
    exit 30
  fi
fi
# Try global create-react-app if available
if command -v create-react-app >/dev/null 2>&1; then
  echo "Using global create-react-app" >"$LOG"
  if create-react-app . --use-npm --template cra-template-minimal >"$LOG" 2>&1; then
    if [ -f package.json ] && [ -f public/index.html ] && [ -f src/index.js ]; then
      [ -f .env ] || cat > .env <<'ENV'
REACT_APP_API_URL=http://localhost:8000
ENV
      echo "CRA scaffold complete" >> "$LOG"
      exit 0
    else
      echo "WARN: CRA did not produce expected files, falling back" >>"$LOG"
    fi
  else
    echo "WARN: create-react-app failed; see $LOG" >&2
  fi
fi
# Fallback: minimal manual scaffold (CRA-compatible)
cat > package.json <<'PJ'
{
  "name": "backendapi-frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test --watchAll=false"
  },
  "dependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "react-scripts": "^5.0.0"
  }
}
PJ
mkdir -p public src
cat > src/index.js <<'JS'
import React from 'react';
import { createRoot } from 'react-dom/client';
const App = ()=> React.createElement('div',null,'Hello from BackendAPI frontend');
createRoot(document.getElementById('root')).render(React.createElement(App));
JS
cat > public/index.html <<'HTML'
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
</head>
<body>
  <div id="root"></div>
</body>
</html>
HTML
[ -f .env ] || cat > .env <<'ENV'
REACT_APP_API_URL=http://localhost:8000
ENV

echo "Manual scaffold created" > "$LOG"
exit 0
