#!/usr/bin/env bash
# DevContainer full rebuild script
# Usage: run this script to clean up all DevContainer resources and rebuild from scratch

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERR]${NC} $1"; }

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="$PROJECT_ROOT/.devcontainer/docker-compose.dev.yml"
REMOVE_VOLUMES=false

for argument in "$@"; do
    case "$argument" in
        --volumes)
            REMOVE_VOLUMES=true
            ;;
        -h|--help)
            log_info "Usage: ./rebuild.sh [--volumes]"
            log_info "  --volumes  Remove named volumes such as the database"
            exit 0
            ;;
    esac
done

log_info "🧹 Cleaning DevContainer stack..."

compose_args=(down --remove-orphans)
if [ "$REMOVE_VOLUMES" = true ]; then
    compose_args+=(--volumes)
fi

log_info "Stopping DevContainer containers..."
docker compose -f "$COMPOSE_FILE" "${compose_args[@]}" \
    && log_success "DevContainer stack stopped" \
    || log_warning "docker compose down completed with warnings"

log_info "Pruning unused Docker resources..."
docker system prune -f

if [ "$REMOVE_VOLUMES" = true ]; then
    log_warning "Named volumes were removed with docker compose down --volumes"
else
    log_info "Named volumes were preserved"
fi

log_success "✅ Cleanup complete!"
log_info ""
log_info "Next steps:"
log_info "  1. Open VS Code in the project folder"
log_info "  2. Press F1 and run: Dev Containers: Rebuild Container"
log_info "  3. Wait for initialization (~3-5 minutes)"
