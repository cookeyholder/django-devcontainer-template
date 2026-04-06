#!/usr/bin/env bash
# DevContainer full rebuild script
# Usage: run this script to clean up all DevContainer resources and rebuild from scratch

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERR]${NC} $1"; }

# Detect project name from parent directory name
PROJECT_NAME="$(basename "$(cd "$(dirname "$0")/.." && pwd)")"
DEVCONTAINER_PREFIX="${PROJECT_NAME}_devcontainer"

log_info "🧹 Cleaning DevContainer resources for: $PROJECT_NAME"

# Stop running containers
log_info "Stopping DevContainer containers..."
docker stop "$(docker ps -q --filter "name=${DEVCONTAINER_PREFIX}")" 2>/dev/null \
    && log_success "Containers stopped" \
    || log_warning "No running containers found"

# Remove containers
log_info "Removing DevContainer containers..."
docker rm "$(docker ps -aq --filter "name=${DEVCONTAINER_PREFIX}")" 2>/dev/null \
    && log_success "Containers removed" \
    || log_warning "No containers to remove"

# Remove volumes (optional)
log_warning "This will remove all volumes including the database!"
read -r -p "Remove volumes? (y/N): " -n 1
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    for vol in postgres_data redis_data venv uv-cache mypy-cache playwright-cache; do
        docker volume rm "${DEVCONTAINER_PREFIX}_${vol}" 2>/dev/null \
            && log_success "Volume removed: $vol" \
            || log_warning "Volume not found: $vol"
    done
else
    log_info "Skipping volume removal — existing data preserved"
fi

# Prune unused Docker resources
log_info "Pruning unused Docker resources..."
docker system prune -f

log_success "✅ Cleanup complete!"
log_info ""
log_info "Next steps:"
log_info "  1. Open VS Code in the project folder"
log_info "  2. Press F1 and run: Dev Containers: Rebuild Container"
log_info "  3. Wait for initialization (~3-5 minutes)"
