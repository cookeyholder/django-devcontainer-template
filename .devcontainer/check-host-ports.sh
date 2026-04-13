#!/usr/bin/env bash
set -euo pipefail

PORTS=(8000 5432 6379)
NAMES=("Django app" "PostgreSQL" "Redis")

is_port_in_use() {
    local port="$1"

    if command -v lsof >/dev/null 2>&1; then
        lsof -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1
        return $?
    fi

    if command -v ss >/dev/null 2>&1; then
        ss -ltn | awk -v p=":${port}" 'NR>1 { if (index($4, p) > 0) { found=1 } } END { exit found?0:1 }'
        return $?
    fi

    return 1
}

find_port_owner() {
    local port="$1"

    if command -v lsof >/dev/null 2>&1; then
        lsof -nP -iTCP:"${port}" -sTCP:LISTEN 2>/dev/null | awk 'NR==2 {print $1 " (pid " $2 ")"}'
        return 0
    fi

    if command -v ss >/dev/null 2>&1; then
        ss -ltnp 2>/dev/null | awk -v p=":${port}" 'index($4, p) > 0 { print; exit }' | sed -E 's/.*users:\(\("([^"]+)".*pid=([0-9]+).*/\1 (pid \2)/'
        return 0
    fi

    echo "unknown process"
}

has_conflict=0

for i in "${!PORTS[@]}"; do
    port="${PORTS[$i]}"
    name="${NAMES[$i]}"

    if is_port_in_use "${port}"; then
        has_conflict=1
        owner="$(find_port_owner "${port}")"
        echo "[devcontainer][ERROR] Port ${port} is already in use (${name})."
        if [ -n "${owner}" ]; then
            echo "[devcontainer][ERROR] Current owner: ${owner}"
        fi
        echo "[devcontainer][ERROR] Build failed because port ${port} is occupied."
    fi
done

if [ "${has_conflict}" -eq 1 ]; then
    echo "[devcontainer][ERROR] Please free the occupied port(s) or adjust .devcontainer/docker-compose.dev.yml."
    exit 1
fi

echo "[devcontainer] Host port precheck passed (8000, 5432, 6379 are available)."
