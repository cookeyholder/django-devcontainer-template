#!/usr/bin/env bash
# Convenience script to install and configure pre-commit hooks
# Run inside the DevContainer or locally after activating the venv

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

# Move to project root
cd "$(dirname "$0")/.."

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log_error "Not inside a Git repository"
    exit 1
fi

log_info "🔧 Configuring pre-commit hooks..."

# Ensure pre-commit is available
if ! command -v pre-commit >/dev/null 2>&1; then
    log_warning "pre-commit not found, attempting to install..."
    if command -v uv >/dev/null 2>&1; then
        uv pip install pre-commit || uv pip install --system pre-commit
    elif [ -f .venv/bin/pip ]; then
        .venv/bin/pip install pre-commit
    else
        log_error "Cannot install pre-commit — activate a venv or install uv first"
        exit 1
    fi
fi

log_success "pre-commit $(pre-commit --version)"

# Check config exists
if [ ! -f ".pre-commit-config.yaml" ]; then
    log_error ".pre-commit-config.yaml not found at project root"
    exit 1
fi

log_info "Installing hooks..."
pre-commit install --hook-type pre-commit --hook-type pre-push \
    && log_success "pre-commit hooks installed" \
    || { log_error "pre-commit install failed"; exit 1; }

# Configure git identity defaults if not set
if ! git config user.email >/dev/null 2>&1; then
    git config --global user.email "dev@localhost" \
        && log_success "Git email set to dev@localhost" \
        || log_warning "Could not set git email"
fi

if ! git config user.name >/dev/null 2>&1; then
    git config --global user.name "Developer" \
        && log_success "Git name set to Developer" \
        || log_warning "Could not set git name"
fi

log_success "✅ pre-commit setup complete"
log_info "Run a quick check: pre-commit run --all-files"
