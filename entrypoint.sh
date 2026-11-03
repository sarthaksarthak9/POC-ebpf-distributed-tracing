#!/bin/sh
# Stands in for an IPSL start script: does work before node starts, then hands over.
set -e

echo "[entrypoint] starting before the application"

# Simulated secret fetch, as a script pulling from a secrets manager would.
if [ -f /etc/poc-secret/token ]; then
  APP_SECRET="$(cat /etc/poc-secret/token)"
else
  APP_SECRET="simulated-secret"
fi
export APP_SECRET
echo "[entrypoint] secret loaded"

# Overwrites NODE_OPTIONS on purpose: the case that drops the operator's agent.
export NODE_OPTIONS="--max-old-space-size=256"
echo "[entrypoint] NODE_OPTIONS=$NODE_OPTIONS"

exec node /app/app.js
